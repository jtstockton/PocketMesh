# MeshCore Protocol Reference

This document provides links to the official MeshCore protocol documentation from the firmware repository.

## Official MeshCore Firmware Repository

**Repository**: https://github.com/meshcore-dev/MeshCore

The MeshCore firmware is a lightweight C++ library for multi-hop packet routing on embedded systems using LoRa radios.

## Protocol Documentation

The official protocol specifications are maintained in the MeshCore firmware repository at:

https://github.com/meshcore-dev/MeshCore/tree/main/docs

### Available Documentation

1. **[Packet Structure](https://github.com/meshcore-dev/MeshCore/blob/main/docs/packet_structure.md)**
   - Binary packet format specification
   - Header breakdown (routing type, payload type, version)
   - Route types (flood, direct, transport)
   - Payload type values
   - Maximum packet sizes and constraints

2. **[Payloads](https://github.com/meshcore-dev/MeshCore/blob/main/docs/payloads.md)**
   - Detailed payload type specifications
   - Node advertisements
   - Request/Response structures
   - Plain text messages
   - Group messaging (text and datagram)
   - Anonymous requests
   - Control data packets
   - Encryption and MAC usage

3. **[Stats Binary Frames](https://github.com/meshcore-dev/MeshCore/blob/main/docs/stats_binary_frames.md)**
   - Binary frame structures for companion radio statistics
   - Command and response codes
   - Core statistics (battery, uptime, errors)
   - Radio statistics (RSSI, SNR, airtime)
   - Packet statistics (sent, received, flood/direct breakdown)
   - Code examples in C/C++, Python, and TypeScript

4. **[FAQ](https://github.com/meshcore-dev/MeshCore/blob/main/docs/faq.md)**
   - Comprehensive frequently asked questions
   - Setup and configuration guides
   - Troubleshooting information
   - Server administration
   - Device-specific guidance

## Related Documentation

### PocketMesh Implementation Documentation

This repository contains documentation for the Swift implementation of the MeshCore protocol:

- **[MeshCore API Reference](api/MeshCore.md)** - Swift implementation API
- **[Protocol Internals](../MeshCore/Sources/MeshCore/MeshCore.docc/Articles/ProtocolInternals.md)** - Client perspective on packet building/parsing
- **[Binary Protocol](../MeshCore/Sources/MeshCore/MeshCore.docc/Articles/BinaryProtocol.md)** - Remote node queries and binary protocol usage

### Other Resources

- **MeshCore Main Website**: https://meshcore.co.uk/
- **Firmware Flasher**: https://flasher.meshcore.co.uk/
- **Python Library** (meshcore_py): https://github.com/meshcore-dev/meshcore_py
- **JavaScript Library** (meshcore.js): https://github.com/liamcottle/meshcore.js

## Notes

- The PocketMesh Swift implementation is a port of the Python library (meshcore_py)
- Protocol documentation is subject to updates in the official firmware repository
- For the most current protocol specifications, always refer to the official MeshCore firmware repository

## License

- MeshCore firmware: MIT License
- PocketMesh (this repository): GNU General Public License v3.0
- Swift MeshCore implementation: MIT License
