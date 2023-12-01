const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Market", function () {
  let usdt, market, nft, accountA, accountB;
  const baseURI = "https://sameple.com/";
  const price = "0x0000000000000000000000000000000000000000000000000001c6bf52634000";

  beforeEach(async () => {
    [accountA, accountB] = await ethers.getSigners();
    const USDTContract = await ethers.getContractFactory("cUSDT");
    usdt = await USDTContract.deploy();
    const MyNFTContract = await ethers.getContractFactory("MyNFT");
    nft = await MyNFTContract.deploy();
    const MarketContract = await ethers.getContractFactory("Market");
    market = await MarketContract.deploy(usdt.target, nft.target);

    for (let i = 0; i < 2; i++) {
      await nft.safeMint(accountA.address, baseURI + i.toString());
      await nft.approve(market.target, i);
    }

    await usdt.transfer(accountB.address, "10000000000000000000000");
    await usdt.connect(accountB).approve(market.target, "1000000000000000000000000");
  });

  it('its erc20 address should be usdt', async function () {
    expect(await market.erc20()).to.equal(usdt.target);
  });

  it('its erc721 address should be nft', async function () {
    expect(await market.erc721()).to.equal(nft.target);
  });

  it('accountA should have 2 nfts', async function () {
    expect(await nft.balanceOf(accountA.address)).to.equal(2);
  });

  it('accountB should have 10000 USDT', async function () {
    expect(await usdt.balanceOf(accountB.address)).to.equal("10000000000000000000000");
  });

  it('accountB should have 0 nfts', async function () {
    expect(await nft.balanceOf(accountB.address)).to.equal(0);
  });

  async function listNFT(tokenId) {
    await market.connect(accountA).listNFTToMarket(nft, tokenId, price);
  }

  it('accountA can list two nfts to market', async function () {
    for (let tokenId = 0; tokenId < 2; tokenId++) {
      await listNFT(tokenId);
    }

    expect((await market.listings(0))[3]).to.equal(true);
    expect((await market.listings(1))[3]).to.equal(true);
  });

  it('accountA can unlist one nft from market', async function () {
    for (let tokenId = 0; tokenId < 2; tokenId++) {
      await listNFT(tokenId);
    }

    expect((await market.listings(1))[3]).to.equal(true);

    await market.connect(accountA).unlistNFTFromMarket(1)

    expect((await market.listings(1))[3]).to.equal(false);
  })

  it('accountA can change price of nft from market', async function () {
    for (let tokenId = 0; tokenId < 2; tokenId++) {
      await listNFT(tokenId);
    }

    await market.connect(accountA).changeNFTPrice(1, 123456789)

    expect((await market.listings(1))[2]).to.equal(123456789);
  })

  it('accountB can buy nft from market', async function () {
    for (let tokenId = 0; tokenId < 2; tokenId++) {
      await listNFT(tokenId);
    }

    expect(await market.getListLength()).to.equal(2);
    await market.connect(accountB).buyNFT(1, { value: ethers.parseUnits('500000000000000', 'wei') })

    expect(await nft.ownerOf(1)).to.equal(accountB.address);
  })

})