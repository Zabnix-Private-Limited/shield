require('dotenv/config');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  console.log("=== DETAILED INTENTS AUDIT ===");
  const intents = await pool.query('SELECT * FROM wallet_recharge_intents ORDER BY id DESC LIMIT 5');
  console.log("Intents:", JSON.stringify(intents.rows, null, 2));

  console.log("\n=== RECENT CASH WALLET TX FOR INTENT 6 & 7 & 8 ===");
  const cashTx = await pool.query("SELECT * FROM cash_wallet_transactions WHERE reference_id IN ('6', '7', '8', '9') OR reference_type = 'MANUAL_RECHARGE_APPROVAL'");
  console.log("Cash Wallet Tx:", JSON.stringify(cashTx.rows, null, 2));

  console.log("\n=== RECENT WALLET TX FOR INTENT 6 & 7 & 8 ===");
  const walletTx = await pool.query("SELECT * FROM wallet_transactions WHERE reference_id IN ('6', '7', '8', '9')");
  console.log("Wallet Tx:", JSON.stringify(walletTx.rows, null, 2));

  console.log("\n=== WALLETS FOR CUST 30 (wallet_id 26) & CUST 29 ===");
  const wallets = await pool.query("SELECT * FROM wallets WHERE id IN (26, 24, 25)");
  console.log("Wallets:", JSON.stringify(wallets.rows, null, 2));
}

main()
  .catch(console.error)
  .finally(() => pool.end());
