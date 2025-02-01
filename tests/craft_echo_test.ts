import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new category",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-category', [
                types.utf8("Woodworking"),
                types.utf8("Projects involving wood crafting")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        
        let getBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'get-category', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        const category = getBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(category['name'], "Woodworking");
    }
});

Clarinet.test({
    name: "Can create a new tutorial with category and tags",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create category first
        chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-category', [
                types.utf8("Woodworking"),
                types.utf8("Projects involving wood crafting")
            ], wallet1.address)
        ]);
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("DIY Bookshelf"),
                types.utf8("A simple bookshelf tutorial"),
                types.utf8("Wood, screws, tools"),
                types.uint(0),
                types.list([types.utf8("woodworking"), types.utf8("furniture")])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        
        let getBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'get-tutorial', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        const tutorial = getBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(tutorial['category-id'], types.uint(0));
    }
});

Clarinet.test({
    name: "Can search tutorials by tag",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create category
        chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-category', [
                types.utf8("Woodworking"),
                types.utf8("Projects involving wood crafting")
            ], wallet1.address)
        ]);
        
        // Create tutorial
        chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("DIY Bookshelf"),
                types.utf8("A simple bookshelf tutorial"),
                types.utf8("Wood, screws, tools"),
                types.uint(0),
                types.list([types.utf8("woodworking"), types.utf8("furniture")])
            ], wallet1.address)
        ]);
        
        let searchBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'search-tutorials-by-tag', [
                types.utf8("furniture")
            ], wallet1.address)
        ]);
        
        const results = searchBlock.receipts[0].result.expectOk();
        assertEquals(results.length, 1);
    }
});
