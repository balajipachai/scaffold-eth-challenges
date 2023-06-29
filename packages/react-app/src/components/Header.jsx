import React from "react";
import { PageHeader } from "antd";

// displays a page header

export default function Header() {
  return (
    <a href="path/to/meta/multi/sig/wallet/on/testnet" target="_blank" rel="noopener noreferrer">
      <PageHeader
        title="MetaMultiSigWallet"
        subTitle="This is a smart contract that acts as an off-chain signature-based shared wallet amongst different signers that showcases use of meta-transaction knowledge and ECDSA recover()."
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
