{{ config(
        schema = 'cow_protocol_ethereum',
        alias='solvers',
        post_hook='{{ expose_spells(blockchains = \'["ethereum"]\',
                                    spell_type = "project",
                                    spell_name = "cow_protocol",
                                    contributors = \'["bh2smith", "gentrexha"]\') }}'
)}}

-- Find the PoC Query here: https://dune.com/queries/1276806
WITH
-- Aggregate the solver added and removed events into a single table
-- with true/false for adds/removes respectively
solver_activation_events as (
    select solver, evt_block_number, evt_index, True as activated
    from {{ source('gnosis_protocol_v2_ethereum', 'GPv2AllowListAuthentication_evt_SolverAdded') }}
    union
    select solver, evt_block_number, evt_index, False as activated
    from {{ source('gnosis_protocol_v2_ethereum', 'GPv2AllowListAuthentication_evt_SolverRemoved') }}
),
-- Sorting by (evt_block_number, evt_index) allows us to pick the most recent activation status of each unique solver
ranked_solver_events as (
    select
        rank() over (partition by solver order by evt_block_number desc, evt_index desc) as rk,
        solver,
        evt_block_number,
        evt_index,
        activated as active
    from solver_activation_events
),
registered_solvers as (
    select solver, active
    from ranked_solver_events
    where rk = 1
),
-- Manually inserting environment and name for each "known" solver
known_solver_metadata (address, environment, name) as (
    select *
    from (
        VALUES   (0xf2d21ad3c88170d4ae52bbbeba80cb6078d276f4, 'prod', 'MIP'),
                 (0x15f4c337122ec23859ec73bec00ab38445e45304, 'prod', 'Gnosis_ParaSwap'),
                 (0xde1c59bc25d806ad9ddcbe246c4b5e5505645718, 'prod', 'Gnosis_1inch'),
                 (0x340185114f9d2617dc4c16088d0375d09fee9186, 'prod', 'Naive'),
                 (0x833f076d182123ca8dde2743045ea02957bd61ef, 'prod', 'Baseline'),
                 (0xe92f359e6f05564849afa933ce8f62b8007a1d5d, 'prod', 'Gnosis_0x'),
                 (0x77ec2a722c2393d3fd64617bbaf1499c713e616b, 'prod', 'Quasimodo'),
                 (0xa6ddbd0de6b310819b49f680f65871bee85f517e, 'prod', 'Legacy'),
                 (0x2d15894fac906386ff7f4bd07fceac43fcf80c73, 'prod', 'DexCowAgg'),
                 (0xa97DEF4fBCBa3b646dd169Bc2eeE40f0f3fE7771, 'prod', 'Gnosis_BalancerSOR'),
                 (0x6fa201C3Aff9f1e4897Ed14c7326cF27548d9c35, 'prod', 'Otex'),
                 (0xe58c68679e7aab8ef83bf37e88b18eb1f6e30e22, 'prod', 'PLM'),
                 (0x0e8F282CE027f3ac83980E6020a2463F4C841264, 'prod', 'Legacy'),
                 (0x7A0A8890D71A4834285efDc1D18bb3828e765C6A, 'prod', 'Naive'),
                 (0x3Cee8C7d9B5C8F225A8c36E7d3514e1860309651, 'prod', 'Baseline'),
                 (0xe8fF24ec26bd46E0140d1824DA44eFad2a0920B5, 'prod', 'MIP'),
                 (0x731a0A8ab2C6FcaD841e82D06668Af7f18e34970, 'prod', 'Quasimodo'),
                 (0xb20B86C4e6DEEB432A22D773a221898bBBD03036, 'prod', 'Gnosis_1inch'),
                 (0xE9aE2D792F981C53EA7f6493A17Abf5B2a45a86b, 'prod', 'Gnosis_ParaSwap'),
                 (0xdA869Be4AdEA17AD39E1DFeCe1bC92c02491504f, 'prod', 'Gnosis_0x'),
                 (0x6D1247b8ACf4dFD5Ff8cfD6C47077ddC43d4500E, 'prod', 'DexCowAgg'),
                 (0xF7995B6B051166eA52218c37b8d03A2A6bbeF3DA, 'prod', 'Gnosis_BalancerSOR'),
                 (0xc9ec550BEA1C64D779124b23A26292cc223327b6, 'prod', 'Otex'),
                 (0x149d0f9282333681Ee41D30589824b2798E9fb47, 'prod', 'PLM'),
                 (0xe18B5632DF2Ec339228DD65e4D9F004eF59653d3, 'prod', 'Atlas'),
                 (0xA21740833858985e4D801533a808786d3647Fb83, 'prod', 'Laertes'),
                 (0x398890BE7c4FAC5d766E1AEFFde44B2EE99F38EF, 'prod', 'Seasolver_v1'),
                 (0x97Ec0a17432D71a3234EF7173C6B48a2C0940896, 'prod', 'Quasilabs'),
                 (0xF5181183D43796120a004130d0CaeE5B2DF2D441, 'prod', 'DMA'),
                 (0xbff9a1b539516f9e20c7b621163e676949959a66, 'prod', 'Raven'),
                 (0x55A37A2E5e5973510Ac9D9C723aeC213fA161919, 'prod', 'Barter'),
                 (0x4F422556FaD14720B2691359fAd0C0F6B1B39113, 'prod', 'Naive'),
                 (0x96a3B53197eA4941482b142F5036E6432086Da8a, 'prod', 'Baseline'),
                 (0x8366812163991Dd7a54A0ec6191e5E5961Db845b, 'prod', 'Gnosis_1inch'),
                 (0x7AC1E2F8593c096Da0A94B71b6f70ca81b6b86F0, 'prod', 'Gnosis_ParaSwap'),
                 (0x8419FF1bCBCe6f0233cf3460B28c32b6951Fc457, 'prod', 'Gnosis_0x'),
                 (0xc20e52dDaFB05c67D78A440f2eAe344EB230A3dA, 'prod', 'Gnosis_BalancerSOR'),
                 (0x511d452b738b3f1aDA0E74e7A3412F5D975FC548, 'prod', 'Otex'),
                 (0x84d143682764DD1f42C4de763262107BD90c4F42, 'prod', 'PLM'),
                 (0x31A9Ec3A6E29039C74723E387DE42b79E6856FD8, 'prod', 'Laertes'),
                 (0x43872b55A12E087935765611851E94e3f0a79249, 'prod', 'Seasolver'),
                 (0x1e8D9a45175B2a4122F7827ce1eA3B08327b2ba0, 'prod', 'Quasilabs'),
                 (0xD8b9c8e1a94baEAaf4D1CA2C45723eb88236130E, 'prod', 'Raven'),
                 (0x0C60276BeaDc5BA35007661A89E0d5E7476523f8, 'prod', 'Barter'),
                 (0x452d604f08affFc4E87E74e3279BdBdeCeD07232, 'prod', 'PropellerSwap'),
                 (0xAd897CF33E5AF59F33C1fD19490C5b94a8a2759b, 'prod', 'Enso'),
                 (0x1A7a08423ab83E7939bf1DF95952347D425e0A0A, 'prod', 'Naive'),
                 (0xB9332b6301e5983272c30dd5b48a4e3B1664511b, 'prod', 'Baseline'),
                 (0x6F799f4bF6c1C56FB8d890E9E0FFF2934b0dE157, 'prod', 'Gnosis_1inch'),
                 (0xdd2e786980CD58ACc5F64807b354c981f4094936, 'prod', 'Gnosis_ParaSwap'),
                 (0xc74b656bd2EBe313D26d1ac02BcF95b137D1C857, 'prod', 'Gnosis_0x'),
                 (0xD50ECb485dCf5D97266122DfED979587Dd8923Ac, 'prod', 'Gnosis_BalancerSOR'),
                 (0x4339889FD9dFCa20a423fbA011e9dfF1C856CAEb, 'prod', 'GlueX_Protocol'),
                 (0xE3067c7C27c1038dE4e8AD95a83b927D23dFBD99, 'prod', 'PLM'),
                 (0x047a2fbe8aEF590d4EB8942426a24970af301875, 'prod', 'Laertes'),
                 (0x0DdcB0769a3591230cAa80F85469240b71442089, 'prod', 'Seasolver'),
                 (0x9b7e7f21d98f21C0354035798C40E9040e25787f, 'prod', 'Quasilabs'),
                 (0x241f4d70e8f2EA8Ab160E376236029565A1F04bf, 'prod', 'Raven'),
                 (0xbf54079c9Bc879Ae4dD6BC79bCe11d3988fD9C2b, 'prod', 'Barter'),
                 (0xc9f2e6ea1637E499406986ac50ddC92401ce1f58, 'prod', 'PropellerSwap'),
                 (0x0Ab21031124AF2165586Fbb495d93725A372C227, 'prod', 'Enso'),
                 (0xFf662Eedb413273B6727e1F59755607CA6876044, 'prod', 'OpenOcean_Aggregator'),
                 (0xBEAf89aEc78A2990BE29E2a317feed6B75Bc78Cd, 'prod', 'Quasimodo'),
                 (0x16C473448E770Ff647c69CBe19e28528877fba1B, 'prod', 'Copium_Capital'),
                 (0x4FC4a61a3b99A1ad4A61b03f3752CA12B4A17646, 'prod', 'Rizzolver'),
                 (0xD1508A211D98bb81195dC1F9533eDcdf68aDF036, 'prod', 'Furucombo'),
                 (0x8646Ee3c5e82b495Be8F9FE2f2f213701EeD0edc, 'prod', 'Seasolver_v2'),
                 (0x9528e8c42F7e109bADED964E2D927fD5B6ca71E9, 'prod', 'Odos'),
                 (0x755BaE1cd46C9C27A3230AeF0CE923BDa13d29F7, 'prod', 'Fractal'),
                 (0x8F70A86c1309d8B1F5BefC58948e7386Fd495875, 'prod', 'Tsolver'),
                 (0xbAda55BaBEE5D2B7F3B551f9da846838760E068C, 'prod', 'Project_Blanc'),
                 (0xA883710b6DBf008a1CC25722C54583E35884a209, 'prod', 'Horadrim'),
                 (0xc10D4DfDA62227d9EC23Ab0010E2942e48338A60, 'prod', 'Apollo'),
                 (0x008300082C3000009e63680088f8c7f4D3ff2E87, 'prod', 'Copium_Capital'),
                 (0xC7899Ff6A3aC2FF59261bD960A8C880DF06E1041, 'prod', 'Barter'),
                 (0x8A75ee64b4A40f679aD98Bcc38312702971e07B7, 'prod', 'OneBit_Quant'),
                 (0x2224eAaCC7c2DBf85d5355BAb9E9271e01d30b55, 'prod', 'Sector_Finance'),
                 (0x9DFc9Bb0FfF2dc96728D2bb94eaCee6ba3592351, 'prod', 'Rizzolver'),
                 (0x6bf97aFe2D2C790999cDEd2a8523009eB8a0823f, 'prod', 'Portus'),
                 (0x95480d3f27658e73b2785d30beb0c847d78294c7, 'prod', 'Fractal'),
                 (0x00806DaA2Cfe49715eA05243FF259DeB195760fC, 'prod', 'Quasilabs'),
                 (0x28B1bd44996105b5c14c4dE41093226Ff78A4eB1, 'prod', '0x'),
                 (0x04B89dBce06e7Aa2F4BBA78969ADD4576eB94788, 'prod', 'ApeOut_1inch'),
                 (0xbada5552a3e5e2fb57db982e29257821a2cf192d, 'prod', 'Project_Blanc'),
                 (0x34717040928D7fd8154d4612f3228EFf14521023, 'prod', 'Laita'),
                 (0xdcE5B9574C9A18B4f1713C80BfC53623c007e7e1, 'prod', 'OKX'),
                 (0x42cb97c2695cF6227C3a1323A1942089ABc9716B, 'prod', 'Elfomo'),
                 (0xA7842153fDe380A864726d0E91f14F6FFAb7d46C, 'prod', 'Wraxyn'),
                 (0xDFddAdd85FE5A8A0943A2DD263F8fE5302A7d027, 'prod', 'Unizen'),
                 (0xbB786564a4d6A41370bA782c2a398CF0aAE52B94, 'prod', 'ExtQuasimodo'),
                 (0x658614f5065Cf018A2A24082f6983e833ac5f0E7, 'barn', 'ExtQuasimodo'),
                 (0xb856279C12a45Acb9E18D50943f029021dE2a65C, 'barn', 'Unizen'),
                 (0x949CbEB40AA624D449A80C7A33F02148F93B6235, 'barn', 'Wraxyn'),
                 (0x6b8Dc2Dd45bBF6A71a987b61cC4Dbbdf7C601c20, 'barn', 'Elfomo'),
                 (0xD2E90778eE3F480d305FF535bE88f5AF9F2ac85c, 'barn', 'OKX'),
                 (0xBab555BaBEe5d867983902bC8db8F707157245Be, 'barn', 'Project_Blanc'),
                 (0x854490ef1d402D4f6fce05aBefE1C676eB0DCD74, 'barn', 'ApeOut_1inch'),
                 (0xBB765c920f86e2A2654c4B82deB5BC2E092fF93b, 'barn', 'Portus'),
                 (0xcC73072B53697911Ff394ae01D3de59c9900b0b0, 'barn', '0x'),
                 (0xd0bA1b1782fbdE45edAb392428f60e14827D08EC, 'barn', 'Laita'),
                 (0x7E2eF26AdccB02e57258784957922AEEFEe807e5, 'barn', 'Quasilabs'),
                 (0x5131590ca2E9D3edC182581352b289dcaE83430c, 'barn', 'Portus'),
                 (0x2a2883ade8ce179265f12fc7b48a4b50b092f1fd, 'barn', 'Fractal'),
                 (0x26B5e3bF135D3Dd05A220508dD61f25BF1A47cBD, 'barn', 'Rizzolver'),
                 (0xA6A871b612bCE899b1CbBad6E545e5e47Da98b87, 'barn', 'Barter'),
                 (0xa08B00576aeE8d8dd960E08298FAc9fD7C756e36, 'barn', 'Apollo'),
                 (0x2c3A1c33d96C9DcA1c34EB234B1e65F79dEaE60e, 'barn', 'Horadrim'),
                 (0xa5559C2E1302c5Ce82582A6b1E4Aec562C2FbCf4, 'barn', 'Project_Blanc'),
                 (0xa432cea087311d7cd07925d70f799eE94E7893a4, 'barn', 'Tsolver'),
                 (0xAb11302CB4f7C417e527A4d39C22Aa9f04EdB07D, 'barn', 'Fractal'),
                 (0xf13eaf9093a210EBdaBa581f5448ffA545EE2E65, 'barn', 'Odos'),
                 (0x94aEF67903bFe8Bf65193A78074C887ba901d043, 'barn', 'Seasolver_v2'),
                 (0x279fb872beaF64E94890376725C423c0820eDA97, 'barn', 'Furucombo'),                 
                 (0x2854C9A92cd1dC65BdDF45aFE397D9d75D4718C8, 'barn', 'Rizzolver'),
                 (0x8E8C00aD7011AabEa0E06e984cfA7194CF8b16b0, 'barn', 'Copium_Capital'),
                 (0xaaC451d13cF8D6915f859f4c7Bc26dA2df10ECA6, 'barn', 'Quasimodo'),
                 (0x9902F0B57b6B8b2Fa7339Cd3eFe0710CF63c86d6, 'barn', 'OpenOcean_Aggregator'),
                 (0x40ADd124002E47119E9DeACdF650dE150F637b6f, 'barn', 'Enso'),
                 (0x69f9365405762405cc17f7979aa8e94fd95c1e80, 'barn', 'Barter'),
                 (0xFFC5E9d86c0e069f8B037c841ACc72cF94eeBaD8, 'barn', 'Barter'),
                 (0x1857afb4da9bd4cc1c6e5287ad41cb5be469f14e, 'barn', 'Raven'),
                 (0x5B2F5e5C94a5De698e2DeC7f30E90069eb3b12bb, 'barn', 'DMA'),
                 (0x872A1B63A739190D0780721d57D8d92ef766Db35, 'barn', 'Quasilabs'),
                 (0x8a4e90e9AFC809a69D2a3BDBE5fff17A12979609, 'barn', 'Seasolver_v1'),
                 (0x0a308697e1d3a91dcB1e915C51F8944AaEc9015F, 'barn', 'Laertes'),
                 (0x8567351D6989d83513D3BC3ad951CcCe363941e3, 'barn', 'Atlas'),
                 (0x109BF9E0287Cc95cc623FBE7380dD841d4bdEb03, 'barn', 'Otex'),
                 (0x70f3c870b6e7e1d566e40c41e2e3d6e895fcee23, 'barn', 'Quasimodo'),
                 (0x97dd6a023b06ba4722aF8Af775ec3C2361e66684, 'barn', 'Gnosis_0x'),
                 (0x6372bcbf66656e91b9213b61d861b5e815296207, 'barn', 'Gnosis_ParaSwap'),
                 (0x158261d17d2983b2cbaecc1ae71a34617ae4cb16, 'barn', 'MIP'),
                 (0x8c9d33828dace1eb9fc533ffde88c4a9db115061, 'barn', 'Gnosis_1inch'),
                 (0xbfaf2b5e351586551d8bf461ba5b2b5455b173da, 'barn', 'Baseline'),
                 (0xb8650702412d0aa7f01f6bee70335a18d6a78e77, 'barn', 'Naive'),
                 (0x583cD88b9D7926357FE6bddF0E8950557fcDA0Ca, 'barn', 'DexCowAgg'),
                 (0x6c2999b6b1fad608ecea71b926d68ee6c62beef8, 'barn', 'Legacy'),
                 (0xED94b86275447e28ddbDd17BBEB1f62D607b5119, 'barn', 'Legacy'),
                 (0x8ccc61dba297833dbe5d95fd6360f106b9a7576e, 'barn', 'Naive'),
                 (0x0d2584da2f637805071f184bcfa1268ebae8a24a, 'barn', 'Baseline'),
                 (0xa0044c620da7f2876da7004719b8370eb7be5e50, 'barn', 'MIP'),
                 (0xda324c2f06d3544e7965767ce9ca536dcb67a660, 'barn', 'Quasimodo'),
                 (0xe33062a24149f7801a48b2675ed5111d3278f0f5, 'barn', 'Gnosis_1inch'),
                 (0x080a8b1e2f3695e179453c5e617b72a381be44b9, 'barn', 'Gnosis_ParaSwap'),
                 (0xde786877a10dbb7eba25a4da65aecf47654f08ab, 'barn', 'Gnosis_0x'),
                 (0xdae69affe582d36f330ee1145995a53fab670962, 'barn', 'DexCowAgg'),
                 (0x0b78e29ee55aa73b366730cf512d65c514eeb196, 'barn', 'Gnosis_BalancerSOR'),
                 (0x22dee0935c77d32c7241362b14e76fc2d5ef657d, 'barn', 'Gnosis_BalancerSOR'),
                 (0x5b0bfe439ab45a4f002c259b1654ed21c9a42d69, 'barn', 'PLM'),
                 (0xC1624D29b82314Cd5cF52dEB293c87794bFAa9f0, 'barn', 'Legacy'),
                 (0x9AF3E1C8257557E2D70074fa03317F1A11595d02, 'barn', 'Naive'),
                 (0x542AAD0402F973a6FCFbf5d60dfC1b0C4233118c, 'barn', 'Baseline'),
                 (0x340c0C9E87C1E1ae5677506412e988748d8417ce, 'barn', 'Gnosis_1inch'),
                 (0x641830bD5E9F283e8f26c60846195e2201dFD09F, 'barn', 'Gnosis_ParaSwap'),
                 (0xeF7D51bD026E60ca75c2155419F29C0d31a6611C, 'barn', 'Gnosis_0x'),
                 (0x31Ac5E51a168B5179c703f3b05F120748C8c7c88, 'barn', 'Gnosis_BalancerSOR'),
                 (0xe374f64513f2432BcbF964B5ab84bD350D1FF222, 'barn', 'Otex'),
                 (0x3cdC01749eEEb4A26b1a9a9611328F232bE06be7, 'barn', 'PLM'),
                 (0xDE478f29C9566499f741cBF91CB068F1C2614B69, 'barn', 'Laertes'),
                 (0xD01BA5b3C4142F358EfFB4d6Cb44A11E31600330, 'barn', 'Seasolver'),
                 (0xF330Ee61d01ef1AC9FFA64662263e5E2DE93bbdE, 'barn', 'Quasilabs'),
                 (0x3C3513c88bD7A919Cb732F777Cd80cd773Beb011, 'barn', 'Raven'),
                 (0xAC0128ACC5c15945aB4E81F09f58CF05ec1844Ed, 'barn', 'Barter'),
                 (0xd3eEc78a89B04f95965927F408F07C13996B8378, 'barn', 'PropellerSwap'),
                 (0xDF4296e752FD08b2d7Db4101B98a48b74E59FD56, 'barn', 'Legacy'),
                 (0x2456A4C1241E43E11b0B8F80e31C940bebD9090f, 'barn', 'Naive'),
                 (0x01246d541E732D7F15d164331711edfF217e4665, 'barn', 'Baseline'),
                 (0x8616DCDFcecBdE13ccd89eAC358Dc5aBDa79ec31, 'barn', 'Gnosis_1inch'),
                 (0x460aAc34690189911CCB49d36E55Ab548CF8a9A1, 'barn', 'Gnosis_ParaSwap'),
                 (0xA697c60706210A5ec6F9CCce364C507e604D9462, 'barn', 'Gnosis_0x'),
                 (0x849BBdF910465913272a8262dDA44279a82c5C76, 'barn', 'Gnosis_BalancerSOR'),
                 (0x08924194cedd747dc85025B2b30A98d3AE1cE21d, 'barn', 'GlueX_Protocol'),
                 (0x27AC9Ed6b768D232855473600a7880a974B71780, 'barn', 'PLM'),
                 (0x8B54b4F5271a216cE18324f2F2891056F305dBeb, 'barn', 'Laertes'),
                 (0xAc6Cc8E2f0232B5B213503257C861235F4ED42c1, 'barn', 'Seasolver'),
                 (0x68005a99946447be44D594832E1B164f6C034e63, 'barn', 'Quasilabs'),
                 (0x5FcBF7f2F4B9a9a63F7dDE9aa89388d52702b3e4, 'barn', 'Raven'),
                 (0x5f7A6aeec3D3E80558278632954DA4b730996F83, 'barn', 'Barter'),
                 (0x3Bf7c0e1728fB64bb0973b1e2A342F1C7eb1bb8e, 'barn', 'PropellerSwap'),
                 (0xEADA531BC5361C9287088D857512e0CA812EAa68, 'barn', 'Enso'),
                 (0xe2823b5bD541ba8BFF3D4BF55396567440772Eab, 'barn', 'OneBit_Quant'),
                 (0x71cac0127254DEfFf2c7386E6286AeaF947F033B, 'barn', 'Sector_Finance'),
                 (0x0798540ee03a8c2e68cef19c56d1faa86271d5cf, 'service', 'Withdraw'),
                 (0xdf30c9502eafea21ecc8410108dda338dd5047c5, 'service', 'Withdraw'),
                 (0x256bb5ad3dbdf61ae08d7cbc0b9223ccb1c60aae, 'service', 'Withdraw'),
                 (0x84e5c8518c248de590d5302fd7c32d2ae6b0123c, 'service', 'Withdraw'),
                 (0xa03be496e67ec29bc62f01a428683d7f9c204930, 'service', 'Withdraw'),
                 (0x2caef7f0ee82fb0abf1ab0dcd3a093803002e705, 'test', 'Test Solver 1'),
                 (0x56d4ed5e49539ebb1366c7d6b8f2530f1e4fe753, 'test', 'Test Solver 2'),
                 (0x83919ba112Fae537d4889e7932a64bE9ECB25dF8, 'barn', 'Apollo'),
                 (0xD2ADF24253056D45731a8561749fC9b2ffa4Fe19, 'prod', 'Apollo'),
                 (0x4dd1be0Cd607E5382Dd2844fA61D3a17e3e83D56, 'prod', 'Rizzolver'),
                 (0x7f2cb2C1B2dfCc4212CBa59ef0a61d9CdE20158D, 'barn', 'PLM'),
                 (0x1b99451f62a8574f8413F5A3FC80B99b29701C16, 'prod', 'PLM')
    ) as _
)
-- Combining the metadata with current activation status for final table
select solver as address,
       case when environment is not null then environment else 'new' end as environment,
       case when name is not null then name else 'Uncatalogued'      end as name,
      active
from registered_solvers
left outer join known_solver_metadata on solver = address
