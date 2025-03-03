import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

Clarinet.test({
    name: "Can edit own tutorial",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create tutorial
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("Original Title"),
                types.utf8("Original Description"),
                types.utf8("Original Materials"),
                types.uint(0),
                types.list([types.utf8("tag")])
            ], wallet1.address)
        ]);
        
        // Edit tutorial
        block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'edit-tutorial', [
                types.uint(0),
                types.utf8("New Title"),
                types.utf8("New Description"),
                types.utf8("New Materials")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Cannot edit other's tutorial",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Create tutorial
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8("Title"),
                types.utf8("Description"),
                types.utf8("Materials"),
                types.uint(0),
                types.list([types.utf8("tag")])
            ], wallet1.address)
        ]);
        
        // Try to edit as different user
        block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'edit-tutorial', [
                types.uint(0),
                types.utf8("New Title"),
                types.utf8("New Description"),
                types.utf8("New Materials")
            ], wallet2.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(401);
    }
});
