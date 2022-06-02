// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "./IORG.sol";
import "./IORGReceiver.sol";

contract ORG is Context, IORG {
    using Address for address;
    using Arrays for uint256[];
    using Arrays for address[];

    struct ORGMetadata {
        uint256 id;
        string name;
        string desc;
        string uri;
    }

    ORGMetadata metadata;

    // Mapping from organization id to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from organization metadata hash to organization id
    mapping(uint256 => ORGMetadata) public _organizationMetadata;

    // Mapping owner address to organization count
    mapping(address => uint256) private _organizations;

    // Mapping owner address to organization list
    mapping(address => uint256[]) private _organizationsList;

    function organizationOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), "address zero is not a valid owner");
        return _organizations[owner];
    }

    function organizationLists(address owner)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(owner != address(0), "address zero is not a valid owner");
        return _organizationsList[owner];
    }

    function ownerOf(uint256 organizationId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[organizationId];
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }

    function _createOrg(
        address to,
        string memory name,
        string memory desc,
        string memory uri,
        uint256 organizationId
    ) internal virtual {
        metadata = ORGMetadata(organizationId, name, desc, uri);
        _organizationMetadata[organizationId] = metadata;
        _organizationsList[to].push(organizationId);

        _create(to, organizationId);
    }

    function _deleteOrg(uint256 organizationId) internal virtual {
        address owner = ORG.ownerOf(organizationId);

        _beforeorganizationTransfer(owner, address(0), organizationId);

        _organizations[owner] -= 1;
        delete _owners[organizationId];
        delete _organizationMetadata[organizationId];
        _deleteORGList(owner, organizationId);

        emit Transfer(owner, address(0), organizationId);

        _afterorganizationTransfer(owner, address(0), organizationId);
    }

    function _transfer(address to, uint256 organizationId) internal virtual {
        _safeTransfer(_msgSender(), to, organizationId, "");
    }

    function _deleteORGList(address owner, uint256 organizationId)
        internal
        virtual
    {
        for (
            uint256 index = 0;
            index < _organizationsList[owner].length;
            index++
        ) {
            if (_organizationsList[owner][index] == organizationId) {
                _remove(owner, index);
                break;
            }
        }
    }

    function _remove(address owner, uint256 _index) internal virtual {
        require(
            _index < _organizationsList[owner].length,
            "index out of bound"
        );

        for (
            uint256 i = _index;
            i < _organizationsList[owner].length - 1;
            i++
        ) {
            _organizationsList[owner][i] = _organizationsList[owner][i + 1];
        }
        _organizationsList[owner].pop();
    }

    function _create(address to, uint256 organizationId) internal virtual {
        require(to != address(0), "create to the zero address");

        _beforeorganizationTransfer(address(0), to, organizationId);

        _organizations[to] += 1;
        _owners[organizationId] = to;

        emit Transfer(address(0), to, organizationId);

        _afterorganizationTransfer(address(0), to, organizationId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnORGReceived(from, to, tokenId, data),
            "transfer to non ORGReceiver implementer"
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 organizationId
    ) internal virtual {
        require(
            ORG.ownerOf(organizationId) == from,
            "ORG: transfer from incorrect owner"
        );
        require(to != address(0), "ORG: transfer to the zero address");

        _beforeorganizationTransfer(from, to, organizationId);

        _deleteORGList(from, organizationId);
        _organizationsList[to].push(organizationId);

        _organizations[from] -= 1;
        _organizations[to] += 1;
        _owners[organizationId] = to;

        emit Transfer(from, to, organizationId);

        _afterorganizationTransfer(from, to, organizationId);
    }

    function _checkOnORGReceived(
        address from,
        address to,
        uint256 organizationId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IORGReceiver(to).onORGReceived(
                    _msgSender(),
                    from,
                    organizationId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IORGReceiver.onORGReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ORG: transfer to non ORGReceiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeorganizationTransfer(
        address from,
        address to,
        uint256 organizationId
    ) internal virtual {}

    function _afterorganizationTransfer(
        address from,
        address to,
        uint256 organizationId
    ) internal virtual {}
}
