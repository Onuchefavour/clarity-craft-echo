import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new tutorial",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("DIY Bookshelf"),
                types.utf8("A simple bookshelf tutorial"),
                types.utf8("Wood, screws, tools")
            ], wallet1.address)
        ]);
        
        // First tutorial should have ID 0
        block.receipts[0].result.expectOk().expectUint(0);
        
        // Verify tutorial details
        let getBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'get-tutorial', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        const tutorial = getBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(tutorial['creator'], wallet1.address);
        assertEquals(tutorial['likes'], types.uint(0));
    }
});

Clarinet.test({
    name: "Can like a tutorial",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Create tutorial first
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("DIY Bookshelf"),
                types.utf8("A simple bookshelf tutorial"),
                types.utf8("Wood, screws, tools")
            ], wallet1.address)
        ]);
        
        // Like the tutorial
        let likeBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'like-tutorial', [
                types.uint(0)
            ], wallet2.address)
        ]);
        
        likeBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify like count
        let getBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'get-tutorial', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        const tutorial = getBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(tutorial['likes'], types.uint(1));
    }
});

Clarinet.test({
    name: "Can tip a tutorial creator",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Create tutorial
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("DIY Bookshelf"),
                types.utf8("A simple bookshelf tutorial"),
                types.utf8("Wood, screws, tools")
            ], wallet1.address)
        ]);
        
        // Send tip
        let tipBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'tip-creator', [
                types.uint(0),
                types.uint(100)
            ], wallet2.address)
        ]);
        
        tipBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify tutorial tips
        let getBlock = chain.mineBlock([
            Tx.contractCall('craft_echo', 'get-tutorial', [
                types.uint(0)
            ], wallet1.address)
        ]);
        
        const tutorial = getBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(tutorial['tips-received'], types.uint(100));
    }
});