import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a
      href="https://sepolia.etherscan.io/address/0x69a7DED635ad8aDc70477B465FE08080a632dd2b#code"
      target="_blank"
      rel="noopener noreferrer"
    >
      <PageHeader title="Stake MTK" subTitle="Stake MTK to earn rMTK (MyToken Rewards)" style={{ cursor: "pointer" }} />
    </a>
  );
}
