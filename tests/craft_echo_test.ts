import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

[... existing tests remain the same ...]

Clarinet.test({
    name: "Fails to create tutorial with invalid parameters",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('craft_echo', 'create-tutorial', [
                types.utf8(""),  // Empty title
                types.utf8("Description"),
                types.utf8("Materials"),
                types.uint(0),
                types.list([types.utf8("tag")])
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectErr().expectUint(400);
    }
});
