import sys
from binascii import hexlify

from flask import Flask, Blueprint, jsonify

from ..ethrpc import EthJsonRpc
from ..webutils import Bytes32Converter

from .common import proof_for_event, proof_for_tx


class ProofBlueprint(Blueprint):
    def __init__(self, rpc, **kwa):
        super().__init__(self, 'proof', __name__, **kwa)
        assert isinstance(rpc, EthJsonRpc)
        self._rpc = rpc

        self.record(lambda s: s.app.url_map.converters.__setitem__('bytes32', Bytes32Converter))

        self.add_url_rule('/<bytes32:tx_id>', 'tx_proof', self.tx_proof, methods=['GET'])
        self.add_url_rule('/<bytes32:tx_id>/<int:log_idx>', 'event_proof', self.event_proof, methods=['GET'])

    def tx_proof(self, tx_id):
        proof = proof_for_tx(self._rpc, '0x' + tx_id)
        return jsonify(dict(proof=hexlify(proof).decode('ascii')))

    def event_proof(self, tx_id, log_idx):
        proof = proof_for_event(self._rpc, '0x' + tx_id, log_idx)
        return jsonify(dict(proof=hexlify(proof).decode('ascii')))


def main(rpc=None):
    if rpc is None:
        rpc = EthJsonRpc()

    proof_bp = ProofBlueprint(rpc)

    app = Flask(__name__)
    app.register_blueprint(proof_bp, url_prefix='/proof')

    app.run(use_reloader=False)

    return 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
