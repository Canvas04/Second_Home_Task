const {expect} = require('chai')
const {ethers} = require('hardhat')

describe('Marketplace', () => {
    let instance
    let owner, user1, user2
    before(async () => {
        ;[owner, user1, user2] = await ethers.getSigners()
        const factory = await ethers.getContractFactory('Marketplace', owner)
        instance = await factory.deploy()
    })

    it('Should create good', async () => {
        await instance.connect(owner).createProduct({
            name: 'T-short',
            price: 2000,
            status: 'isAvalable',
        })
        const products = await instance.getProducts()
        expect(products[0].name).to.equal('T-short')
        expect(products[0].price).to.equal(2000)
        expect(products[0].status).to.equal('isAvalable')
    })

    it('Should register user', async () => {
        await instance.connect(user1).registerUser('Ruslan', 'ruslan@mts.ru')

        const userInfo = await instance.getUserInfo(user1.address)

        expect(userInfo.name).to.equal('Ruslan')
        expect(userInfo.email).to.equal('ruslan@mts.ru')
        expect(userInfo.isRegistered).to.be.true
    })

    it('Should handle unregistered users', async () => {
        const userInfo = await instance.getUserInfo(user2.address)

        expect(userInfo.isRegistered).to.be.false
        expect(userInfo.name).to.equal('')
        expect(userInfo.email).to.equal('')
    })

    it('User can buy a product', async () => {
        console.log(user1)
       const transfer = await instance.transferEther(0x5A321C2eD3E8aD7d725D5D4a4dD5aB5a6E7d8F9C,10)
       console.log(transfer)
    })
})
