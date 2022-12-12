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
            | Tier             | Rarity      | Image                                                              | Animation URI                                               | Animation Hash                                                   | Quantity | Number |
            | The Ultimate Low | Ultrarare   | ipfs://bafybeia3g433ghgkqofvdyf63vrgs64ybnb6q3glty4qjyk67hdtmaw3wm | ipfs://bafybeiep5oh5pu536to6vhvfjb5ztkx2ykqpfbr2zalexzgq6zqjjyr54u | 8f23e95c39df8bdd0e94b7c0aad3d989af00f449b16911e53e235797e89d4879 | 3        | 5      |
            | The Low Low      | Rare        | ipfs://bafybeidhj37sswlzaclfmg3eg733gqmopp2ronvfcx7vjh67fequ5cox4a | ipfs://bafybeifd52lxad44vtvr5ixinaqsnnjogmrvtib3sluxcnj5m2ofjsrb2a | 919a5db6c42bb5e5e974cb9d8c8c4917a3df6b235a406cf7f6ed24fa7694aafb | 11       | 4      |
            | The Medium Low   | Uncommon    | ipfs://bafybeif3dupvjfszlc6vro3ruadocemw2r2mt44qomd2baxayb4v3glhey | ipfs://bafybeifolz3aej7yz4huykyrzegj2fejicvybyu5sgmuthudex25fylyfq | 05bbc9c8bea2dc831d2e760c37f760a65e012ea7d5aab8fb92f26ae80424aad4 | 22       | 3      |
            | The Basic Low    | Common      | ipfs://bafybeicvdszyeodww2os5z33u5rtorfqw3eae5wv5uqcx2a32ovklcpwoa | ipfs://bafybeifboxzmkmcik755qguivpbtrca33pasz3xxwjziv27zeuxuoaaet4 | af8c6f9c161ce427521dc654cf90d22b78580f2a60fb52bb553a428158a62460 | 75       | 2      |
            | The Lightest Low | Ultracommon | ipfs://bafybeifwg6zzxxbit7diqfojrgskd7eb5mdryhxtenlx2lroaef2mxd5ga | ipfs://bafybeih72wvfeo6fest5ombybn3ak5ca7mqip5dzancs7mqrgafaudxx3y | afcb97e97e179a83ead16c7466725cf3d875a7c92bdb312884ad9db511e0fc52 | 111      | 1      |
        And calling reveal a second time should not change any tiers

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