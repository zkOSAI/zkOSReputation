anchor build
anchor deploy

anchor run initialize --provider.cluster devnet

[scripts]
initialize = "scripts/initialize.ts"

import * as anchor from "@coral-xyz/anchor";
import { zkOSReputation } from "../target/types/zkOS_reputation";

const main = async () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.zkOSReputation as anchor.Program<zkOSReputation>;

  const settings = anchor.web3.Keypair.generate();
  const statistics = anchor.web3.Keypair.generate();

  await program.methods
    .initialize(provider.wallet.publicKey) // token mint address
    .accounts({
      settings: settings.publicKey,
      statistics: statistics.publicKey,
      owner: provider.wallet.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .signers([settings, statistics])
    .rpc();
};

main().catch(console.error);
