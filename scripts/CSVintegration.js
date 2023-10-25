const Web3 = require('web3');
const fs = require('fs');
const csv = require('csv-parser'); // CSV parsing library

// Initialize a Web3 instance with your Ethereum node URL
const web3 = new Web3('https://goerli.infura.io/v3/5e382490498c4aad803e4c239fabdeed');

// Set your Ethereum wallet's private key and address
const privateKey = 'ffd77dc3ac8e9d44ffffe4efa3f482f36d6355db6e1cbefcd0256bda3b845485';
const senderAddress = '0x017E942eEacdB0134B4E5f820AF15597FfD72AB5';

// Set the contract address and ABI
const contractAddress = '0x681BE99EE02415E5844a8E7a17176A3dB94024D5';
const contractABI = [
        // Replace with the actual ABI of your TokenVesting contract
        // ...
      
        // ABI for the createVestingSchedule function
        {
          constant: false,
          inputs: [
            {
              name: '_beneficiary',
              type: 'address',
            },
            {
              name: '_start',
              type: 'uint256',
            },
            {
              name: '_cliff',
              type: 'uint256',
            },
            {
              name: '_duration',
              type: 'uint256',
            },
            {
              name: '_slicePeriodSeconds',
              type: 'uint256',
            },
            {
              name: '_revocable',
              type: 'bool',
            },
            {
              name: '_amount',
              type: 'uint256',
            },
          ],
          name: 'createVestingSchedule',
          outputs: [],
          payable: false,
          stateMutability: 'nonpayable',
          type: 'function',
        },
      ];

// Create a contract instance
const contract = new web3.eth.Contract(contractABI, contractAddress);

// Function to send a transaction to create a vesting schedule
async function createVestingSchedule(
        beneficiary,
        start,
        cliff,
        duration,
        slicePeriodSeconds,
        revocable,
        amount
      ) {
        const senderAccount = web3.eth.accounts.privateKeyToAccount(privateKey);
      
        const data = contract.methods
          .createVestingSchedule(
            beneficiary,
            start,
            cliff,
            duration,
            slicePeriodSeconds,
            revocable,
            amount
          )
          .encodeABI();
      
        const gasPrice = await web3.eth.getGasPrice();
        const nonce = await web3.eth.getTransactionCount(senderAccount.address);
      
        const tx = {
          from: senderAccount.address,
          to: contractAddress,
          data: data,
          gas: 2000000, // Adjust gas limit as needed
          gasPrice: web3.utils.toWei(gasPrice, 'gwei'),
          nonce: nonce,
        };
      
        const signedTx = await web3.eth.accounts.signTransaction(tx, privateKey);
        const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
      
        return receipt;
      }

// Read data from the CSV file and process each row
async function processCSV() {
  try {
    fs.createReadStream('CSV2.csv')
      .pipe(csv({ headers: true }))
      .on('data', async (record) => {
        console.log("RECORDS  : ",record)
        const beneficiary = record['_0'];
        const start = parseInt(record['_1']);
        const cliff = 0; // You can set the cliff to 0 for now
        const duration = parseInt(record['_2']);
        const slicePeriodSeconds = 3600; // Adjust as needed
        const revocable = true; // Or false if non-revocable
        const amount = parseInt(record['_3']);

        const receipt = await createVestingSchedule(
          beneficiary,
          start,
          cliff,
          duration,
          slicePeriodSeconds,
          revocable,
          amount
        );

        console.log(`Vesting schedule created for beneficiary: ${beneficiary}`);
        console.log('Transaction Receipt:', receipt);
      })
      .on('end', () => {
        console.log('CSV file processing complete.');
      });
  } catch (err) {
    console.error('Error reading or processing the CSV file:', err);
  }
}

// Run the script
processCSV();
