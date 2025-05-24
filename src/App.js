import { useEffect, useState } from 'react';
import { ethers } from 'ethers';

// Components
import Navigation from './components/Navigation';
import Search from './components/Search';
import Home from './components/Home';

// ABIs
import RealEstate from './abis/RealEstate.json'
import Escrow from './abis/Escrow.json'

// Config
import config from './config.json';

function App() {
	const [provider, setProvider] = useState(null)
	const [escrow, setEscrow] = useState(null)
	const [homes, setHomes] = useState([])
	const [account, setAccount] = useState(null)

	const loadBlockchainData = async () => {
		const provider = new ethers.providers.Web3Provider(window.ethereum)
		setProvider(provider)

		const network = await provider.getNetwork()

		const realEstate = new ethers.Contract(config[network.chainId].realEstate.address, RealEstate, provider)
		const totalSupply = await realEstate.totalSupply()
		const homes = []  
		for (var i = 1; i <= totalSupply; ++i) {
			const uri = await realEstate.tokenURI(i)
			let url = uri
			if (uri.startsWith('ipfs://')) {
			  url = uri.replace('ipfs://', 'https://ipfs.io/ipfs/')
			}
		  
			const response = await fetch(url)
			if (!response.ok) {
			  console.error(`Failed to fetch token URI ${url}: ${response.status}`)
			  continue
			}
		  
			try {
			  const metadata = await response.json()
			  console.log(metadata)
			  homes.push(metadata)
			} catch (err) {
			  console.error(`Invalid JSON from ${url}`, err)
			}
		}
		setHomes(homes)

		const escrow = new ethers.Contract(config[network.chainId].escrow.address, Escrow, provider)
		setEscrow(escrow)

		// config[network.chainId].realEstate.address
		// config[network.chainId].escrow.address

		window.ethereum.on('accountsChanged', async () => {
			const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
			const account = ethers.utils.getAddress(accounts[0])
			setAccount(account)
		})
	}


	useEffect(() => {
		loadBlockchainData()
	}, [])

	const renderHomes = () => {
		return homes.map((home, index) => (
			<div className='card' key={index}>
				<div className='card__image'>
					<img src='' alt='Home' />
				</div>
				<div className='card__info'>
					<h4>1 ETH</h4>
					<p>
						<strong>1</strong> bds |
						<strong>2</strong> ba |
						<strong>3</strong> sqft
					</p>
					<p>1234 Elm St</p>
				</div>
			</div>
		))
	}

	return (
		<div>
			<Navigation account={account} setAccount={setAccount} />
			<Search />

			<div className='cards__section'>

				<h3>Homes for you</h3>

				<hr />

				<div className='cards'>
					{renderHomes()}
				</div>

			</div>

		</div>
	);
}

export default App;
