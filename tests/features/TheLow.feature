Feature: Partywithray Proof of Membership

    As a Partywithray Fan,
    I want to buy "The Low" Proof of Membership NFT,
    so that I can get more involved in his community and receive exclusive merch and access.

    Background: Deploy and Mint
        Given the Partywithray Proof of Membership NFT contract is deployed

    Scenario: Mint on creation
        Then the name should be "partywithray - The Low" and the symbol should "LOW"
        And the supply should be 222
        And all 222 NFTs should have the pre-reveal art
        And each NFT title should be "The Low {id}/222"
        And each NFT description should be "partywithray Proof of Membership"
        And royalties should be set at 10% going to the "Big Night" address
        And the ability to mint more NFTs should be frozen

    Scenario: List for sale
        When we list the Partywithray NFTs on OpenSea
        Then 211 NFTs should be listed as Buy It Now for 0.0111 ETH
        And 11 NFTs should be held in the TODOBigNightENSName vault

    Scenario: Reveal when sells out
        Given 11 NFTs were held for promo and all remaining 211 NFTs were sold
        When we reveal the art
        Then there should be 222 tokens with the following metadata and quantities:
            | Tier             | Rarity      | Image      | Quantity | Number |
            | The Ultimate Low | Ultrarare   | ipfs://xyz | 3        | 5      |
            | The Low Low      | Rare        | ipfs://xyz | 11       | 4      |
            | The Medium Low   | Uncommon    | ipfs://xyz | 22       | 3      |
            | The Basic Low    | Common      | ipfs://xyz | 75       | 2      |
            | The Lightest Low | Ultracommon | ipfs://xyz | 111      | 1      |
        And the ability to update metadata should be frozen
        And the ability to reduce supply should be frozen

    Scenario: Reveal when does not sell out
        Given 11 NFTs were held for promo and less than remaining 211 NFTs were sold
        When we decide to vault a percentage and burn a percentage of unsold NFTs
        And we reveal the art
        Then there should be the correct amount of tokens in the vault and in total supply
        And the ability to update metadata should be frozen
        And the ability to reduce supply should be frozen


        # Reveal goals:
    # rarity IDs are not known in advance (even to the team) but provably fair
    #
# TODO What percentage should secondary royalties be (5–10% standard)
# TODO What should our collection page look like
#   - Logo
#   - Featured
#   - Banner
#   - Name
#   - URL
#   - Description
#   - Category
#   - Social links (Twitter, Discord, Instagram)
#   - Web links (Website, Medium, Telegram)
#   - Royalties
# TODO Decide on release timing — how about 11/22/22 to open up 2 week pre-reveal phase?