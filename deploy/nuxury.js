const settings = require('../settings')

module.exports = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const token = await deploy('Nuxury', {
    from: deployer,
    log: true,
    deterministicDeployment: false,
    args: [],
  })
  console.log('Nuxury deployed on:', token.address)
}
