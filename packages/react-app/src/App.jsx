import WalletConnectProvider from "@walletconnect/web3-provider";
//import Torus from "@toruslabs/torus-embed"
import WalletLink from "walletlink";
import { Alert, Button, Col, Menu, Row, List, Card, Input, notification } from "antd";
import "antd/dist/antd.css";
import React, { useCallback, useEffect, useState } from "react";
import { BrowserRouter, Link, Route, Switch } from "react-router-dom";
import Web3Modal from "web3modal";
import "./App.css";
import {
  Account,
  Address,
  AddressInput,
  Balance,
  Contract,
  Faucet,
  GasGauge,
  Header,
  Ramp,
  ThemeSwitch,
} from "./components";
import { INFURA_ID, NETWORK, NETWORKS } from "./constants";
import { Transactor } from "./helpers";
import {
  useBalance,
  useContractLoader,
  useContractReader,
  useGasPrice,
  useOnBlock,
  useUserProviderAndSigner,
} from "eth-hooks";
import { useEventListener } from "eth-hooks/events/useEventListener";
import { useExchangeEthPrice } from "eth-hooks/dapps/dex";
// import Hints from "./Hints";
import { ExampleUI, Hints, Subgraph } from "./views";

import { useContractConfig } from "./hooks";
import Portis from "@portis/web3";
import Fortmatic from "fortmatic";
import Authereum from "authereum";
import humanizeDuration from "humanize-duration";

const { ethers } = require("ethers");
/*
    Welcome to 🏗 scaffold-eth !

    Code:
    https://github.com/austintgriffith/scaffold-eth

    Support:
    https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA
    or DM @austingriffith on twitter or telegram

    You should get your own Infura.io ID and put it in `constants.js`
    (this is your connection to the main Ethereum network for ENS etc.)


    🌏 EXTERNAL CONTRACTS:
    You can also bring in contract artifacts in `constants.js`
    (and then use the `useExternalContractLoader()` hook!)
*/

/// 📡 What chain are your contracts deployed to?
const targetNetwork = NETWORKS.sepolia; // <------- select your target frontend network (localhost, rinkeby, xdai, mainnet)

// 😬 Sorry for all the console logging
const DEBUG = false;
const NETWORKCHECK = true;

// 🛰 providers
// if (DEBUG) console.log("📡 Connecting to Mainnet Ethereum");
// const mainnetProvider = getDefaultProvider("mainnet", { infura: INFURA_ID, etherscan: ETHERSCAN_KEY, quorum: 1 });
// const mainnetProvider = new InfuraProvider("mainnet",INFURA_ID);
//
// attempt to connect to our own scaffold eth rpc and if that fails fall back to infura...
// Using StaticJsonRpcProvider as the chainId won't change see https://github.com/ethers-io/ethers.js/issues/901
const scaffoldEthProvider = navigator.onLine
  ? new ethers.providers.StaticJsonRpcProvider("https://rpc.scaffoldeth.io:48544")
  : null;
const poktMainnetProvider = navigator.onLine
  ? new ethers.providers.StaticJsonRpcProvider(
      "https://eth-mainnet.gateway.pokt.network/v1/lb/611156b4a585a20035148406",
    )
  : null;
const mainnetInfura = navigator.onLine
  ? new ethers.providers.StaticJsonRpcProvider("https://mainnet.infura.io/v3/" + INFURA_ID)
  : null;
// ( ⚠️ Getting "failed to meet quorum" errors? Check your INFURA_ID

// 🏠 Your local provider is usually pointed at your local blockchain
const localProviderUrl = targetNetwork.rpcUrl;
// as you deploy to other networks you can set REACT_APP_PROVIDER=https://dai.poa.network in packages/react-app/.env
const localProviderUrlFromEnv = process.env.REACT_APP_PROVIDER ? process.env.REACT_APP_PROVIDER : localProviderUrl;
// if (DEBUG) console.log("🏠 Connecting to provider:", localProviderUrlFromEnv);
const localProvider = new ethers.providers.StaticJsonRpcProvider(localProviderUrlFromEnv);

// 🔭 block explorer URL
const blockExplorer = targetNetwork.blockExplorer;

// Coinbase walletLink init
const walletLink = new WalletLink({
  appName: "coinbase",
});

// WalletLink provider
const walletLinkProvider = walletLink.makeWeb3Provider(`https://mainnet.infura.io/v3/${INFURA_ID}`, 1);

// Portis ID: 6255fb2b-58c8-433b-a2c9-62098c05ddc9
/*
  Web3 modal helps us "connect" external wallets:
*/
const web3Modal = new Web3Modal({
  network: "mainnet", // Optional. If using WalletConnect on xDai, change network to "xdai" and add RPC info below for xDai chain.
  cacheProvider: true, // optional
  theme: "light", // optional. Change to "dark" for a dark theme.
  providerOptions: {
    walletconnect: {
      package: WalletConnectProvider, // required
      options: {
        bridge: "https://polygon.bridge.walletconnect.org",
        infuraId: INFURA_ID,
        rpc: {
          1: `https://mainnet.infura.io/v3/${INFURA_ID}`, // mainnet // For more WalletConnect providers: https://docs.walletconnect.org/quick-start/dapps/web3-provider#required
          42: `https://kovan.infura.io/v3/${INFURA_ID}`,
          100: "https://dai.poa.network", // xDai
        },
      },
    },
    portis: {
      display: {
        logo: "https://user-images.githubusercontent.com/9419140/128913641-d025bc0c-e059-42de-a57b-422f196867ce.png",
        name: "Portis",
        description: "Connect to Portis App",
      },
      package: Portis,
      options: {
        id: "6255fb2b-58c8-433b-a2c9-62098c05ddc9",
      },
    },
    fortmatic: {
      package: Fortmatic, // required
      options: {
        key: "pk_live_5A7C91B2FC585A17", // required
      },
    },
    // torus: {
    //   package: Torus,
    //   options: {
    //     networkParams: {
    //       host: "https://localhost:8545", // optional
    //       chainId: 1337, // optional
    //       networkId: 1337 // optional
    //     },
    //     config: {
    //       buildEnv: "development" // optional
    //     },
    //   },
    // },
    "custom-walletlink": {
      display: {
        logo: "https://play-lh.googleusercontent.com/PjoJoG27miSglVBXoXrxBSLveV6e3EeBPpNY55aiUUBM9Q1RCETKCOqdOkX2ZydqVf0",
        name: "Coinbase",
        description: "Connect to Coinbase Wallet (not Coinbase App)",
      },
      package: walletLinkProvider,
      connector: async (provider, _options) => {
        await provider.enable();
        return provider;
      },
    },
    authereum: {
      package: Authereum, // required
    },
  },
});

function App(props) {
  const mainnetProvider =
    poktMainnetProvider && poktMainnetProvider._isProvider
      ? poktMainnetProvider
      : scaffoldEthProvider && scaffoldEthProvider._network
      ? scaffoldEthProvider
      : mainnetInfura;

  const [injectedProvider, setInjectedProvider] = useState();
  const [address, setAddress] = useState();

  const logoutOfWeb3Modal = async () => {
    await web3Modal.clearCachedProvider();
    if (injectedProvider && injectedProvider.provider && typeof injectedProvider.provider.disconnect == "function") {
      await injectedProvider.provider.disconnect();
    }
    setTimeout(() => {
      window.location.reload();
    }, 1);
  };

  /* 💵 This hook will get the price of ETH from 🦄 Uniswap: */
  const price = useExchangeEthPrice(targetNetwork, mainnetProvider);

  /* 🔥 This hook will get the price of Gas from ⛽️ EtherGasStation */
  const gasPrice = useGasPrice(targetNetwork, "fast");
  // Use your injected provider from 🦊 Metamask or if you don't have it then instantly generate a 🔥 burner wallet.
  const userProviderAndSigner = useUserProviderAndSigner(injectedProvider, localProvider);
  const userSigner = userProviderAndSigner.signer;

  useEffect(() => {
    async function getAddress() {
      if (userSigner) {
        const newAddress = await userSigner.getAddress();
        setAddress(newAddress);
      }
    }
    getAddress();
  }, [userSigner]);

  // You can warn the user if you would like them to be on a specific network
  const localChainId = localProvider && localProvider._network && localProvider._network.chainId;
  const selectedChainId =
    userSigner && userSigner.provider && userSigner.provider._network && userSigner.provider._network.chainId;

  // For more hooks, check out 🔗eth-hooks at: https://www.npmjs.com/package/eth-hooks

  // The transactor wraps transactions and provides notificiations
  const tx = Transactor(userSigner, gasPrice);

  // Faucet Tx can be used to send funds from the faucet
  const faucetTx = Transactor(localProvider, gasPrice);

  // 🏗 scaffold-eth is full of handy hooks like this one to get your balance:
  const yourLocalBalance = useBalance(localProvider, address);

  // Just plug in different 🛰 providers to get your balance on different chains:
  const yourMainnetBalance = useBalance(mainnetProvider, address);

  const contractConfig = useContractConfig();

  // Load in your local 📝 contract and read a value from it:
  const readContracts = useContractLoader(localProvider, contractConfig);

  // If you want to make 🔐 write transactions to your contracts, use the userSigner:
  const writeContracts = useContractLoader(userSigner, contractConfig, localChainId);

  // EXTERNAL CONTRACT EXAMPLE:
  //
  // If you want to bring in the mainnet DAI contract it would look like:
  const mainnetContracts = useContractLoader(mainnetProvider, contractConfig);

  // If you want to call a function on a new block
  // useOnBlock(mainnetProvider, () => {
  //   console.log(`⛓ A new mainnet block is here: ${mainnetProvider._lastBlockNumber}`);
  //   // TODO @Balaji Add updateTimeLeft callback function which would update the timeLeft in the UI for staking
  // });

  // Then read your DAI balance like:
  // const myMainnetDAIBalance = useContractReader(mainnetContracts, "DAI", "balanceOf", [
  //   "0x34aA3F359A9D614239015126635CE7732c18fDF3",
  // ]);

  //keep track of contract balance to know how much has been staked total:
  const stakerContractBalance = useBalance(
    localProvider,
    readContracts && readContracts.Stake ? readContracts.Stake.address : null,
  );
  // if (DEBUG) console.log("💵 stakerContractBalance", stakerContractBalance);

  // ** keep track of total 'threshold' needed of ETH
  const threshold = useContractReader(readContracts, "Stake", "threshold");
  // console.log("💵 threshold:", threshold);

  const mtkBalance = useContractReader(readContracts, "MyToken", "balanceOf", [address]);
  // console.log("🏵 mtkBalance:", mtkBalance ? ethers.utils.formatEther(mtkBalance) : "...");

  // ** keep track of a variable from the contract in the local React state:
  // const myStakes = useContractReader(readContracts, "Stake", "myStakes", [address]);
  // console.log("💸 myStakes:", myStakes``);
  // const { stakedETV } = myStakes;
  // console.log("stakedETV", stakedETV);

  // ** 📟 Listen for broadcast events
  const stakeEvents = useEventListener(readContracts, "Stake", "Stake", localProvider, 1);
  // console.log("📟 stake events:", stakeEvents);

  const unstakeEvents = useEventListener(readContracts, "Stake", "Unstake", localProvider, 1);

  // ** keep track of a variable from the contract in the local React state:
  const timeLeft = useContractReader(readContracts, "Stake", "timeLeft");
  // console.log("⏳ timeLeft:", timeLeft);

  const totalMTKStaked = useContractReader(readContracts, "Stake", "totalMTKStaked");
  // console.log("💸 totalMTKStaked:", totalMTKStaked);

  /**
   * Fetch values of contract public functions
   */
  const rewardToken = useContractReader(readContracts, "Stake", "rewardToken");
  // console.log("rewardToken: ", rewardToken);

  // ** Listen for when the contract has been 'completed'
  const complete = useContractReader(readContracts, "ExampleExternalContract", "completed");
  // console.log("✅ complete:", complete);

  const etvApproval = useContractReader(readContracts, "MyToken", "allowance", [
    address,
    readContracts && readContracts.Stake ? readContracts.Stake.address : null,
  ]);
  // console.log("🤏 etvApproval", etvApproval);

  // const exampleExternalContractBalance = useBalance(
  //   localProvider,
  //   readContracts && readContracts.ExampleExternalContract ? readContracts.ExampleExternalContract.address : null,
  // );
  // if (DEBUG) console.log("💵 exampleExternalContractBalance", exampleExternalContractBalance);

  let completeDisplay = "";
  if (complete) {
    completeDisplay = (
      <div style={{ padding: 64, backgroundColor: "#eeffef", fontWeight: "bolder", color: "rgba(0, 0, 0, 0.85)" }}>
        🚀 🎖 👩‍🚀 -- Staking App triggered `ExampleExternalContract` -- 🎉 🍾 🎊
        <Balance balance={exampleExternalContractBalance} fontSize={64} /> ETH staked!
      </div>
    );
  }

  const [myStakes, setMyStakes] = useState();
  const [reward, setReward] = useState();
  const [userMTKBalance, setUserMTKBalance] = useState();
  const [rMTKBalance, setrMTKBalance] = useState();
  const [unstakeAmount, setUnstakeAmount] = useState();

  const stakes = useContractReader(readContracts, "Stake", "myStakes", [address]);
  const userReward = useContractReader(readContracts, "Stake", "earnedRewards", [address]);
  const uMTKBalance = useContractReader(readContracts, "MyToken", "balanceOf", [address]);
  const rewardBalance = useContractReader(readContracts, "Reward", "balanceOf", [address]);

  useEffect(() => {
    setMyStakes(stakes && stakes.stakedETV ? stakes.stakedETV : 0);
  }, [readContracts, stakes && stakes.stakedETV]);

  useEffect(() => {
    setUnstakeAmount(stakes && stakes.unstakeAmount ? stakes.unstakeAmount : 0);
  }, [readContracts, stakes && stakes.unstakeAmount]);

  useEffect(() => {
    setReward(userReward);
  }, [readContracts, userReward]);

  useEffect(() => {
    setUserMTKBalance(userMTKBalance);
  }, [readContracts, uMTKBalance]);

  useEffect(() => {
    setrMTKBalance(rewardBalance);
  }, [readContracts, rewardBalance]);

  /*
  const addressFromENS = useResolveName(mainnetProvider, "austingriffith.eth");
  console.log("🏷 Resolved austingriffith.eth as:", addressFromENS)
  */

  //
  // 🧫 DEBUG 👨🏻‍🔬
  //
  useEffect(() => {
    if (
      DEBUG &&
      mainnetProvider &&
      address &&
      selectedChainId &&
      yourLocalBalance &&
      yourMainnetBalance &&
      readContracts &&
      writeContracts &&
      mainnetContracts
    ) {
      // console.log("_____________________________________ 🏗 scaffold-eth _____________________________________");
      // console.log("🌎 mainnetProvider", mainnetProvider);
      // console.log("🏠 localChainId", localChainId);
      // console.log("👩‍💼 selected address:", address);
      // console.log("🕵🏻‍♂️ selectedChainId:", selectedChainId);
      // console.log("💵 yourLocalBalance", yourLocalBalance ? ethers.utils.formatEther(yourLocalBalance) : "...");
      // console.log("💵 yourMainnetBalance", yourMainnetBalance ? ethers.utils.formatEther(yourMainnetBalance) : "...");
      // console.log("📝 readContracts", readContracts);
      // console.log("🌍 DAI contract on mainnet:", mainnetContracts);
      // console.log("💵 yourMainnetDAIBalance", myMainnetDAIBalance);
      // console.log("🔐 writeContracts", writeContracts);
    }
  }, [
    mainnetProvider,
    address,
    selectedChainId,
    yourLocalBalance,
    yourMainnetBalance,
    readContracts,
    writeContracts,
    mainnetContracts,
  ]);

  let networkDisplay = "";
  if (NETWORKCHECK && localChainId && selectedChainId && localChainId !== selectedChainId) {
    const networkSelected = NETWORK(selectedChainId);
    const networkLocal = NETWORK(localChainId);
    if (selectedChainId === 1337 && localChainId === 31337) {
      networkDisplay = (
        <div style={{ zIndex: 2, position: "absolute", right: 0, top: 60, padding: 16 }}>
          <Alert
            message="⚠️ Wrong Network ID"
            description={
              <div>
                You have <b>chain id 1337</b> for localhost and you need to change it to <b>31337</b> to work with
                HardHat.
                <div>(MetaMask -&gt; Settings -&gt; Networks -&gt; Chain ID -&gt; 31337)</div>
              </div>
            }
            type="error"
            closable={false}
          />
        </div>
      );
    } else {
      networkDisplay = (
        <div style={{ zIndex: 2, position: "absolute", right: 0, top: 60, padding: 16 }}>
          <Alert
            message="⚠️ Wrong Network"
            description={
              <div>
                You have <b>{networkSelected && networkSelected.name}</b> selected and you need to be on{" "}
                <Button
                  onClick={async () => {
                    const ethereum = window.ethereum;
                    const data = [
                      {
                        chainId: "0x" + targetNetwork.chainId.toString(16),
                        chainName: targetNetwork.name,
                        nativeCurrency: targetNetwork.nativeCurrency,
                        rpcUrls: [targetNetwork.rpcUrl],
                        blockExplorerUrls: [targetNetwork.blockExplorer],
                      },
                    ];
                    // console.log("data", data);

                    let switchTx;
                    // https://docs.metamask.io/guide/rpc-api.html#other-rpc-methods
                    try {
                      switchTx = await ethereum.request({
                        method: "wallet_switchEthereumChain",
                        params: [{ chainId: data[0].chainId }],
                      });
                    } catch (switchError) {
                      // not checking specific error code, because maybe we're not using MetaMask
                      try {
                        switchTx = await ethereum.request({
                          method: "wallet_addEthereumChain",
                          params: data,
                        });
                      } catch (addError) {
                        // handle "add" error
                      }
                    }

                    if (switchTx) {
                      console.log(switchTx);
                    }
                  }}
                >
                  <b>{networkLocal && networkLocal.name}</b>
                </Button>
              </div>
            }
            type="error"
            closable={false}
          />
        </div>
      );
    }
  } else {
    networkDisplay = (
      <div style={{ zIndex: -1, position: "absolute", right: 154, top: 28, padding: 16, color: targetNetwork.color }}>
        {targetNetwork.name}
      </div>
    );
  }

  const loadWeb3Modal = useCallback(async () => {
    const provider = await web3Modal.connect();
    setInjectedProvider(new ethers.providers.Web3Provider(provider));

    provider.on("chainChanged", chainId => {
      console.log(`chain changed to ${chainId}! updating providers`);
      setInjectedProvider(new ethers.providers.Web3Provider(provider));
    });

    provider.on("accountsChanged", () => {
      console.log(`account changed!`);
      setInjectedProvider(new ethers.providers.Web3Provider(provider));
    });

    // Subscribe to session disconnection
    provider.on("disconnect", (code, reason) => {
      console.log(code, reason);
      logoutOfWeb3Modal();
    });
  }, [setInjectedProvider]);

  useEffect(() => {
    if (web3Modal.cachedProvider) {
      loadWeb3Modal();
    }
  }, [loadWeb3Modal]);

  const [route, setRoute] = useState();
  useEffect(() => {
    setRoute(window.location.pathname);
  }, [setRoute]);

  let faucetHint = "";
  const faucetAvailable = localProvider && localProvider.connection && targetNetwork.name.indexOf("local") !== -1;

  const [faucetClicked, setFaucetClicked] = useState(false);
  if (
    !faucetClicked &&
    localProvider &&
    localProvider._network &&
    localProvider._network.chainId === 31337 &&
    yourLocalBalance &&
    ethers.utils.formatEther(yourLocalBalance) <= 0
  ) {
    faucetHint = (
      <div style={{ padding: 16 }}>
        <Button
          type="primary"
          onClick={() => {
            faucetTx({
              to: address,
              value: ethers.utils.parseEther("0.01"),
            });
            setFaucetClicked(true);
          }}
        >
          💰 Grab funds from the faucet ⛽️
        </Button>
      </div>
    );
  }

  const [tokenStakeAmount, setTokenStakeAmount] = useState();
  const [isApproved, setIsApproved] = useState();

  const [tokenUnStakeAmount, setTokenUnStakeAmount] = useState();
  // console.log(`isApproved returned::::::::::::::::::${isApproved}`);

  useEffect(() => {
    setIsApproved(etvApproval);
  }, [readContracts, etvApproval]);

  const [loader, setLoader] = useState();

  let stakeDisplay = "";
  if (mtkBalance) {
    stakeDisplay = (
      <div style={{ padding: 8, marginTop: 32, width: 420, margin: "auto" }}>
        <Card title="Stake tokens">
          <div>
            <div style={{ padding: 8 }}>
              <Input
                style={{ textAlign: "center" }}
                placeholder={"amount of tokens to stake"}
                value={tokenStakeAmount}
                onChange={e => {
                  setTokenStakeAmount(e.target.value);
                }}
                disabled={isApproved == 0}
              />
            </div>
          </div>
          {isApproved > 0 ? (
            <div style={{ padding: 8 }}>
              <Button disabled={true} type={"primary"}>
                Approve
              </Button>
              <Button
                type={"primary"}
                loading={loader}
                onClick={async () => {
                  setLoader(true);
                  await tx(writeContracts.Stake.stake(ethers.utils.parseEther("" + tokenStakeAmount)));
                  setTokenStakeAmount("");
                  setLoader(false);
                }}
              >
                Stake
              </Button>
            </div>
          ) : (
            <div style={{ padding: 8 }}>
              <Button
                type={"primary"}
                loading={loader}
                onClick={async () => {
                  setLoader(true);
                  await tx(writeContracts.MyToken.approve(readContracts.Stake.address, ethers.constants.MaxUint256)); // Give Infinite approval
                  setLoader(false);
                }}
              >
                Approve
              </Button>
              <Button disabled={true} type={"primary"}>
                Stake
              </Button>
            </div>
          )}
        </Card>
      </div>
    );
  }

  return (
    <div className="App">
      {/* ✏️ Edit the header and change the title to your project name */}
      <Header />
      {networkDisplay}
      <BrowserRouter>
        <Menu style={{ textAlign: "center" }} selectedKeys={[route]} mode="horizontal">
          <Menu.Item key="/">
            <Link
              onClick={() => {
                setRoute("/");
              }}
              to="/"
            >
              Stake UI
            </Link>
          </Menu.Item>
          {/* <Menu.Item key="/contracts">
            <Link
              onClick={() => {
                setRoute("/contracts");
              }}
              to="/contracts"
            >
              Debug Contracts
            </Link>
          </Menu.Item> */}
        </Menu>

        <Switch>
          <Route exact path="/">
            {completeDisplay}

            <div style={{ padding: 8, marginTop: 32 }}>
              <div>Stake Contract:</div>
              <Address value={readContracts && readContracts.Stake && readContracts.Stake.address} />
            </div>

            <div style={{ padding: 8 }}>
              <Button
                type={"default"}
                onClick={() => {
                  tx(writeContracts.ClaimMTK.claimFreeTokens());
                }}
                disabled={userMTKBalance > 0}
              >
                📡 Claim Free MTK!
              </Button>
            </div>

            <div style={{ padding: 8, marginTop: 32 }}>
              <div>Timeleft:</div>
              {timeLeft && humanizeDuration(timeLeft.toNumber() * 1000)}
            </div>

            <div style={{ padding: 8 }}>
              <div>MTK Balance | rMTK Balance:</div>
              <Balance balance={uMTKBalance} fontSize={64} />/<Balance balance={rMTKBalance} fontSize={64} />
            </div>

            <div style={{ padding: 8 }}>
              <div>Total staked:</div>
              <Balance balance={totalMTKStaked} fontSize={64} />/<Balance balance={threshold} fontSize={64} />
            </div>

            <div style={{ padding: 8 }}>
              <div>You staked:</div>
              <Balance balance={myStakes && myStakes._hex ? myStakes._hex : 0} fontSize={64} />
            </div>

            <div style={{ padding: 8 }}>
              <div>Rewards:</div>
              <Balance balance={reward} fontSize={64} />
            </div>

            {stakeDisplay}

            <div style={{ padding: 8 }}>
              <Button
                type={"default"}
                onClick={() => {
                  tx(writeContracts.Stake.claimRewards());
                }}
                disabled={reward == 0}
              >
                📡 Claim Rewards!
              </Button>
            </div>

            <div style={{ padding: 8, marginTop: 32, width: 420, margin: "auto" }}>
              <Input
                style={{ textAlign: "center" }}
                placeholder={"amount of tokens to unstake"}
                value={tokenUnStakeAmount}
                onChange={e => {
                  // TODO Add a logic to give pop-up when value is greater than unstakeAmount
                  if (e.target.value > myStakes / 1e18) {
                    setTokenUnStakeAmount("");
                    notification.error({
                      message: "Amount greater than staked value",
                      description: `Staked ${myStakes / 1e18}, Unstake amount ${e.target.value}`,
                      placement: "topRight",
                    });
                  } else {
                    setTokenUnStakeAmount(e.target.value);
                  }
                }}
                disabled={myStakes == 0}
              />
            </div>

            <div style={{ padding: 8 }}>
              <Button
                type={"default"}
                onClick={async () => {
                  setLoader(true);
                  await tx(writeContracts.Stake.unstake(ethers.utils.parseEther("" + tokenUnStakeAmount)));
                  setLoader(false);
                  setTokenUnStakeAmount("");
                }}
                disabled={!tokenUnStakeAmount || tokenUnStakeAmount == 0}
              >
                📡 Unstake!
              </Button>
            </div>

            <div style={{ padding: 8 }}>
              <Button
                type={"default"}
                onClick={() => {
                  tx(writeContracts.Stake.withdraw());
                }}
                disabled={!unstakeAmount || unstakeAmount == 0}
              >
                🏧 Withdraw
              </Button>
            </div>

            {/*
                🎛 this scaffolding is full of commonly used components
                this <Contract/> component will automatically parse your ABI
                and give you a form to interact with it locally
            */}

            <div style={{ width: 500, margin: "auto", marginTop: 64 }}>
              <div>Stake Events:</div>
              <List
                dataSource={stakeEvents}
                renderItem={item => {
                  return (
                    <List.Item key={item.blockNumber}>
                      <Address value={item.args[0]} ensProvider={mainnetProvider} fontSize={16} />
                      <Balance balance={item.args[1]} />
                    </List.Item>
                  );
                }}
              />
            </div>

            <div style={{ width: 500, margin: "auto", marginTop: 64 }}>
              <div>UnStake Events:</div>
              <List
                dataSource={unstakeEvents}
                renderItem={item => {
                  return (
                    <List.Item key={item.blockNumber}>
                      <Address value={item.args[0]} ensProvider={mainnetProvider} fontSize={16} />
                      <Balance balance={item.args[1]} />
                    </List.Item>
                  );
                }}
              />
            </div>

            {/* uncomment for a second contract:
            <Contract
              name="SecondContract"
              signer={userProvider.getSigner()}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
              contractConfig={contractConfig}
            />
            */}
          </Route>
          <Route path="/contracts">
            <Contract
              name="MyToken"
              signer={userSigner}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
              contractConfig={contractConfig}
            />
            <Contract
              name="Stake"
              signer={userSigner}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
              contractConfig={contractConfig}
            />
            <Contract
              name="Reward"
              signer={userSigner}
              provider={localProvider}
              address={address}
              blockExplorer={blockExplorer}
              contractConfig={contractConfig}
            />
          </Route>
        </Switch>
      </BrowserRouter>

      <ThemeSwitch />

      {/* 👨‍💼 Your account is in the top right with a wallet at connect options */}
      <div style={{ position: "fixed", textAlign: "right", right: 0, top: 0, padding: 10 }}>
        <Account
          address={address}
          localProvider={localProvider}
          userSigner={userSigner}
          mainnetProvider={mainnetProvider}
          price={price}
          web3Modal={web3Modal}
          loadWeb3Modal={loadWeb3Modal}
          logoutOfWeb3Modal={logoutOfWeb3Modal}
          blockExplorer={blockExplorer}
        />
        {faucetHint}
      </div>

      <div style={{ marginTop: 32, opacity: 0.5 }}>
        {/* Add your address here */}
        Created by{" "}
        <Address value={"0x63d596e6b6399bbb3cFA3075968946b870045955"} ensProvider={mainnetProvider} fontSize={16} />
      </div>

      {/* 🗺 Extra UI like gas price, eth price, faucet, and support: */}
      <div style={{ position: "fixed", textAlign: "left", left: 0, bottom: 20, padding: 10 }}>
        <Row align="middle" gutter={[4, 4]}>
          <Col span={8}>
            <Ramp price={price} address={address} networks={NETWORKS} />
          </Col>

          <Col span={8} style={{ textAlign: "center", opacity: 0.8 }}>
            <GasGauge gasPrice={gasPrice} />
          </Col>
          <Col span={8} style={{ textAlign: "center", opacity: 1 }}>
            <Button
              onClick={() => {
                window.open("https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA");
              }}
              size="large"
              shape="round"
            >
              <span style={{ marginRight: 8 }} role="img" aria-label="support">
                💬
              </span>
              Support
            </Button>
          </Col>
        </Row>

        <Row align="middle" gutter={[4, 4]}>
          <Col span={24}>
            {
              /*  if the local provider has a signer, let's show the faucet:  */
              faucetAvailable ? (
                <Faucet localProvider={localProvider} price={price} ensProvider={mainnetProvider} />
              ) : (
                ""
              )
            }
          </Col>
        </Row>
      </div>
    </div>
  );
}

export default App;
