#!/bin/bash

function createOrg1() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/org1.service.ru/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org1.service.ru/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-org1 --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/org1.service.ru/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org1's CA cert to org1's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/org1.service.ru/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org1.service.ru/msp/tlscacerts/ca.crt"

  # Copy org1's CA cert to org1's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/org1.service.ru/tlsca"
  cp "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org1.service.ru/tlsca/tlsca.org1.service.ru-cert.pem"

  # Copy org1's CA cert to org1's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/org1.service.ru/ca"
  cp "${PWD}/organizations/fabric-ca/org1/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org1.service.ru/ca/ca.org1.service.ru-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org1 --id.name org1admin --id.secret org1adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/msp" --csr.hosts peer0.org1.service.ru --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org1.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls" --enrollment.profile tls --csr.hosts peer0.org1.service.ru --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls/keystore/"* "${PWD}/organizations/peerOrganizations/org1.service.ru/peers/peer0.org1.service.ru/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.service.ru/users/User1@org1.service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org1.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org1.service.ru/users/User1@org1.service.ru/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org1admin:org1adminpw@localhost:7054 --caname ca-org1 -M "${PWD}/organizations/peerOrganizations/org1.service.ru/users/Admin@org1.service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org1/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org1.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org1.service.ru/users/Admin@org1.service.ru/msp/config.yaml"
}

function createOrg2() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/org2.service.ru/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org2.service.ru/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-org2 --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-org2.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/org2.service.ru/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org2's CA cert to org2's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/org2.service.ru/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org2.service.ru/msp/tlscacerts/ca.crt"

  # Copy org2's CA cert to org2's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/org2.service.ru/tlsca"
  cp "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org2.service.ru/tlsca/tlsca.org2.service.ru-cert.pem"

  # Copy org2's CA cert to org2's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/org2.service.ru/ca"
  cp "${PWD}/organizations/fabric-ca/org2/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org2.service.ru/ca/ca.org2.service.ru-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org2 --id.name org2admin --id.secret org2adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/msp" --csr.hosts peer0.org2.service.ru --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org2.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls" --enrollment.profile tls --csr.hosts peer0.org2.service.ru --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls/keystore/"* "${PWD}/organizations/peerOrganizations/org2.service.ru/peers/peer0.org2.service.ru/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.service.ru/users/User1@org2.service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org2.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org2.service.ru/users/User1@org2.service.ru/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org2admin:org2adminpw@localhost:8054 --caname ca-org2 -M "${PWD}/organizations/peerOrganizations/org2.service.ru/users/Admin@org2.service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org2/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org2.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org2.service.ru/users/Admin@org2.service.ru/msp/config.yaml"
}

function createorg3() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/org3.service.ru/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/org3.service.ru/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 --caname ca-org3 --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-10054-ca-org3.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/peerOrganizations/org3.service.ru/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org3's CA cert to org3's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/peerOrganizations/org3.service.ru/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/org3/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org3.service.ru/msp/tlscacerts/ca.crt"

  # Copy org3's CA cert to org3's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/org3.service.ru/tlsca"
  cp "${PWD}/organizations/fabric-ca/org3/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org3.service.ru/tlsca/tlsca.org3.service.ru-cert.pem"

  # Copy org3's CA cert to org3's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/peerOrganizations/org3.service.ru/ca"
  cp "${PWD}/organizations/fabric-ca/org3/ca-cert.pem" "${PWD}/organizations/peerOrganizations/org3.service.ru/ca/ca.org3.service.ru-cert.pem"

  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-org3 --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-org3 --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-org3 --id.name org3admin --id.secret org3adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca-org3 -M "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/msp" --csr.hosts peer0.org3.service.ru --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org3.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:10054 --caname ca-org3 -M "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls" --enrollment.profile tls --csr.hosts peer0.org3.service.ru --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls/keystore/"* "${PWD}/organizations/peerOrganizations/org3.service.ru/peers/peer0.org3.service.ru/tls/server.key"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:10054 --caname ca-org3 -M "${PWD}/organizations/peerOrganizations/org3.service.ru/users/User1@org3.service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org3.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org3.service.ru/users/User1@org3.service.ru/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://org3admin:org3adminpw@localhost:10054 --caname ca-org3 -M "${PWD}/organizations/peerOrganizations/org3.service.ru/users/Admin@org3.service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/org3/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/org3.service.ru/msp/config.yaml" "${PWD}/organizations/peerOrganizations/org3.service.ru/users/Admin@org3.service.ru/msp/config.yaml"
}

function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/service.ru

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/service.ru

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/service.ru/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy orderer org's CA cert to orderer org's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/service.ru/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/service.ru/msp/tlscacerts/tlsca.service.ru-cert.pem"

  # Copy orderer org's CA cert to orderer org's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/ordererOrganizations/service.ru/tlsca"
  cp "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem" "${PWD}/organizations/ordererOrganizations/service.ru/tlsca/tlsca.service.ru-cert.pem"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/msp" --csr.hosts orderer.service.ru --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/service.ru/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/msp/config.yaml"

  infoln "Generating the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls" --enrollment.profile tls --csr.hosts orderer.service.ru --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the orderer's tls directory that are referenced by orderer startup config
  cp "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/server.key"

  # Copy orderer org's CA cert to orderer's /msp/tlscacerts directory (for use in the orderer MSP definition)
  mkdir -p "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/service.ru/orderers/orderer.service.ru/msp/tlscacerts/tlsca.service.ru-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/service.ru/users/Admin@service.ru/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/service.ru/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/service.ru/users/Admin@service.ru/msp/config.yaml"
}
