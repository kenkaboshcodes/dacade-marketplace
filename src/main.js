import Web3 from "web3"
import { newKitFromWeb3 } from "@celo/contractkit"
import BigNumber from "bignumber.js"
import marketplaceAbi from "../contract/marketplace.abi.json"
import erc20Abi from "../contract/erc20.abi.json"

const ERC20_DECIMALS = 18
const MPContractAddress = "0x4feFd31D24d9865DA1BC92db92E2d3FF3E6151C4"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

const couponButton = document.querySelector('.couponbutton')
let couponCodeValue = ''



let kit
let contract
let artisans = []

const connectCeloWallet = async function () {
  if (window.celo) {
    notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)
  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


  couponButton.addEventListener('click', (e) => {
    e.preventDefault()
    const couponCode = document.querySelector('.couponcode')
    couponCodeValue = couponCode.value 
  })


const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

const getCouponCodes = async function() {
  const coupon = await contract.methods.getCouponCodes().call()
  return coupon
}


const getArtisans = async function() {
  const _artisansLength = await contract.methods.getArtisansLength().call()
  const _artisans = []
  for (let i = 0; i < _artisansLength; i++) {
    let _artisan = new Promise(async (resolve, reject) => {
      let p = await contract.methods.readArtisan(i).call()
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        location: p[4],
        price: new BigNumber(p[5]),
        sold: p[6],
      })
    })
    _artisans.push(_artisan)
  }
  artisans = await Promise.all(_artisans)
  renderArtisans()
}

function renderArtisans() {
  document.getElementById("marketplace").innerHTML = ""
  artisans.forEach((_artisan) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-4"
    newDiv.innerHTML = artisanTemplate(_artisan)
    document.getElementById("marketplace").appendChild(newDiv)
  })
}

function artisanTemplate(_artisan) {
  return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_artisan.image}" alt="...">
      <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
        ${_artisan.sold} Hires
      </div>
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_artisan.owner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">${_artisan.name}</h2>
        <p class="card-text mb-4" style="min-height: 82px">
          ${_artisan.description}             
        </p>
        <p class="card-text mt-4">
          <i class="bi bi-geo-alt-fill"></i>
          <span>${_artisan.location}</span>
        </p>
        <div class="d-grid gap-2">
          <a class="btn btn-lg btn-outline-dark hireBtn fs-6 p-3" id=${
            _artisan.index
          }>
            Hire for ${_artisan.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
          </a>
        </div>
      </div>
    </div>
  `
}

function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}

window.addEventListener("load", async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getArtisans()
  notificationOff()
});

document
  .querySelector("#newArtisanBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newArtisanName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newArtisanDescription").value,
      document.getElementById("newLocation").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString()
    ]
    notification(`⌛ Adding "${params[0]}"...`)
    try {
      const result = await contract.methods
        .writeArtisan(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`🎉 You successfully added "${params[0]}".`)
    getArtisans()
  })

document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("hireBtn")) {
    const index = e.target.id
    notification("⌛ Waiting for payment approval...")
    try {
      
        await approve(artisans[index].price)

    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ Awaiting payment for "${artisans[index].name}"...`)
    try {
      const couponArray = await getCouponCodes()
      if(couponArray.includes(couponCodeValue)) {
        const result = await contract.methods
        .hireArtisanForDiscount(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully hired "${artisans[index].name}".`)
      getArtisans()
      getBalance()
      }
      else{
        const result = await contract.methods
        .hireArtisan(index)
        .send({ from: kit.defaultAccount })
      notification(`🎉 You successfully hired "${artisans[index].name}".`)
      getArtisans()
      getBalance()}
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})  

