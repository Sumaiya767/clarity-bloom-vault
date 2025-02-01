import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("bloom-vault", "create-vault", 
        [types.utf8("My Memories")], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Can create and share a memory",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("bloom-vault", "create-vault",
        [types.utf8("My Memories")],
        wallet_1.address
      ),
      Tx.contractCall("bloom-vault", "create-memory",
        [
          types.utf8("First Memory"),
          types.utf8("A beautiful day"),
          types.utf8("{}")
        ],
        wallet_1.address
      ),
      Tx.contractCall("bloom-vault", "share-memory",
        [
          types.principal(wallet_1.address),
          types.uint(0),
          types.principal(wallet_2.address)
        ],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 3);
    assertEquals(block.receipts[0].result, '(ok true)');
    assertEquals(block.receipts[1].result, '(ok true)');
    assertEquals(block.receipts[2].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Cannot access unauthorized vault",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("bloom-vault", "create-vault",
        [types.utf8("My Memories")],
        wallet_1.address
      ),
      Tx.contractCall("bloom-vault", "create-memory",
        [
          types.utf8("Private Memory"),
          types.utf8("Secret"),
          types.utf8("{}")
        ],
        wallet_2.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[0].result, '(ok true)');
    assertEquals(block.receipts[1].result, 
      `(err ${types.uint(102)})`); // err-vault-not-found
  },
});
