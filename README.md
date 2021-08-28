# WordLines

## Mobile ZK Puzzle Game with NFT rewards

WordLines is a ripoff of [NYT's Letter Boxed game](https://www.nytimes.com/puzzles/letter-boxed) on ethereum. It has a mobile client that connects to mobile wallets and uses NFTs as a reward mechanism for solving puzzles.

This project was made during [ETH Summer](https://summer.ethuniversity.org). Special thanks to @gubsheep for supporting me through this project.

# Client Demo

![Speedy demo](https://media.giphy.com/media/KPMdJ6w23UlFwlyQpF/giphy.gif?cid=790b76114c91f065c33ec290de475a0371971e36dd2acefb&rid=giphy.gif)

### User flow:

- User starts by connecting their wallet to the app via WalletConnect
- User plays game, processes ZK proof, and assembles calldata for a transaction calling the NFT smart contract
- Transaction is submitted back to the wallet, which handles signing, broadcasting, gas pricing etc.

You can play with the demo yourself with TestFlight! [Hit me up](https://nibnalin.me/about/) and I can add you as a tester.

# Product Notes

![game idea](./assets/discord.png)


There were 4 primary ideas when I originally started thinking about this project:

- **Zero knowledge**: Originally, I was motivated by the namesake property of zero knowledge proofs to support "global" puzzles in a decentralised, provable environment (much like how DarkForest uses zk proofs), puzzles like [sudoku](https://github.com/nalinbhardwaj/snarky-sudoku), [poker](https://medium.com/coinmonks/zk-poker-a-simple-zk-snark-circuit-8ec8d0c5ee52) and crosswords seemed like the obvious candidates: You have a relatively simple puzzle, and there's no clean non zero knowledge mechanism to prove your solution outside of sharing the solution itself.

- **NFTs**: Game rewards in the form of NFT would serve as a cool retention loop that make the secondary market of the game itself a fun addon. A lot of games use in-game items and rewards as a game mechanic to bring back users, and NFTs are perhaps the blockchain-native way to encode such items.

- **Mobile**: Mobile gaming is more interesting than PC/web clients to me. If nothing it means you can use push notifications and make games a much more mindless/regular part of their day vs. depending on users to actively seek out your game on their computers. As far as I am aware, there aren't any other open source blockchain based zk games, so I also found the challenge of building this out to be quite technically exciting.

- Time-locked: Originally, I planned to build a mechanism similar to New York Times crosswords. Every day, there would be a new puzzle and you can only solve a particular puzzle and claim its NFT in the 24 hours following release. This would create a somewhat artificial scarcity for tokens and encourage trades in secondary markets. I didn't get to building this out, but I have some thoughts on how the current implementation can be extended to build this. [Hit me up](https://nibnalin.me/about/) if you're building a mechanism like this in your blockchain game!

I ultimately decided to build out my version of NYT's popular daily game [Letter Boxed](https://www.nytimes.com/puzzles/letter-boxed). This is a relatively simple game with rules as follows:

![game rules](./assets/game-rules.png)

Since the game has a pretty visual representation, it comes with the added advantage that the NFT image can be simply a solution to the puzzle! It also comes with the disadvantage that the puzzle, by its very definition, has multiple solutions, and the only clean way to validate them is to encode an entire dictionary of words in the zk circuit (more on that later).

# Technical Notes

The general architecture of the service involves a lot of back and forth between Ethereum chain (via wallet), a central server for computing ZK proofs (sadly, this app isn't truly decentralised due to this limitation 😢), the smart contract that mints the WordLinesToken and finally a Swift client that compiles user inputs into CALLDATA using the contract's ABI.

![insert architecture image]()

More detailed notes on each aspect of the app below:

## ZK circuit

The circuit assumes an input of the following parameters:

- private input "line": your solution to the puzzle
- public input "figure": an encoding of the figure for the puzzle
- public input "dictionary": a dictionary of words considered "valid" for the puzzle figure
- private input "private_address": the address of the user solving this puzzle
- public input "address": copy of private_address.

The first three inputs are used to encode the solution to the proof. The core circuit enforces three rules:

- Every word in the line starts with the letter the previous word ended with.
- Every word belongs to the dictionary.
- All letters of the figure are covered at least once by the word letters

Note that we are not enforcing the "consecutive letters must be from different sides" rule here. That is enforced by the precomputed "dictionary" input: only words with consecutive letters on different sides are made part of the dictionary.

More on enforcement of each of the rules follows, but first, let's talk about polynomial hashing and word representations.

### Polynomial Hashing

### Compression

### Padding

Since circom doesn't natively support variable length inputs, you have to support the maximum input limits possible for your circuit and build out some form of padding support. In this ZK circuit, there are two kinds of padding:

- Letter paddings: Words are limited to having a maximum of 6 characters, so any shorter words are padded with the integer 27.
- Word paddings: The dictionary is limited to 90 inputs (720 words), so any excess words are padded as words with integer 28 repeated many times. The "line" input is limited to 6 words, so they are padded in a similar way.

The primary motivation to distinguish the two types of paddings was to prevent any weird hacks that may try to get around the rules by using word paddings as a line input or vice versa.

### [CheckFigure]()

This function (or *template* in circom parlance)

### [InDictionary]()

### [IsContinual]()


Since the puzzle figure and dictionary themselves are public inputs, anyone can verify that the "line" supplied by the user was valid for a particular puzzle, but not know anything more about that input. The last two inputs are used to prevent replay attacks, more on that in [ERC 721 Smart contract replay attacks](link).

These circuits went through a few iterations, starting with a simple word comparison based circuit, followed by a second step to employ polynomial hashing to reduce inputs by a factor of word length(*6 times*), finally followed by the use of the clever compression trick to store *8 times* as many words per input. The [git history](link) of this project is a cool way to walk through me fumbling my way across each of these ideas.

## ERC721 Smart contract

### Replay attacks

Since the puzzle's proof (the "line") is independent of a user and everyone's proof is public on the Ethereum chain, anyone can theoretically copy an old proof and rebroadcast it as their own. To prevent this, I've added a simple mechanism via the "private_address" and "address" inputs. The smart contract asserts that the NFT minter address matches the "address" input to the circuit, and the circuit itself has a simple assertion that the private input "private_address" does indeed match the public input. This means that each proof is now locked to a single address, and the only way for an attacker to derive a valid proof from someone else's proof is to edit both private and public inputs, rendering it useless.

## Puzzle Generation

## Proof generation server

## Mobile client


