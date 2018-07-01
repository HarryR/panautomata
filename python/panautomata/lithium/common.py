from sha3 import keccak_256

from ..utils import scan_bin


def pack_txn(txn):
    """
    Packs all the information about a transaction into a deterministic fixed-sized array of bytes

        from || to || value || KECCAK256(input)
    """
    fields = [txn['from'], txn['to'], txn['value'], txn['input']]
    # NOTE: some fields have an odd number of zeros, e.g. the 'value' field
    encoded_fields = [scan_bin(x + ('0' * (len(x) % 2))) for x in fields]
    tx_from, tx_to, tx_value, tx_input = encoded_fields

    return b''.join([
        tx_from,
        tx_to,
        tx_value,
        keccak_256(tx_input).digest()
    ])


def pack_log(log):
    """
    Packs a log entry emitted from a contract into a fixed sized number of bytes

        contract-address || event-signature || KECCAK256(event-data)

    It's not possible for transactions and events to be confused.
    Transactions are 128 bytes, logs are 96 bytes

    Indexed parameters are ignored, only the event type and originator contract
    are included along with a hash of the data.

    Event type is a hash of the event signature, e.g. KECCAK256('MyEvent(address,uint256)')
    """
    return b''.join([
        scan_bin(log['address']),
        scan_bin(log['topics'][0]),
        keccak_256(scan_bin(log['data'])).digest()
    ])


def process_block(rpc, block_height):
    """Returns all items within the block"""
    # TODO: return 'ProcessedBlock' object with items, tx_count and log_count members
    block = rpc.eth_getBlockByNumber(block_height, False)
    if not block['transactions']:
        return [], 0, 0

    log_count = 0
    tx_count = 0
    items = []
    for tx_hash in block['transactions']:
        transaction = rpc.eth_getTransactionByHash(tx_hash)

        # Exclude contract creation
        if transaction['to'] is None:
            continue

        tx_count += 1
        items.append(pack_txn(transaction))

        # Process logs for transaction
        receipt = rpc.eth_getTransactionReceipt(tx_hash)
        if receipt['logs']:
            for log_entry in receipt['logs']:
                log_item = pack_log(log_entry)
                items.append(log_item)
                log_count += 1

    return items, tx_count, log_count
