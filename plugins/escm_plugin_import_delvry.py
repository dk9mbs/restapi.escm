from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log
from core.xml_reader import XmlReader

logger=log.create_logger(__name__)

def _validate(params):
    if 'data' not in params:
        return False

    if 'content' not in params['data']:
        return False

    return True

def _inner(is_item, element, stack, globals):
    import uuid

    if is_item:
        pass

    if globals['path']==".DELVRY01.IDOC.E1EDL20.VBELN":
        if not 'orders' in globals:
            globals['orders']=[]
        order={}
        order['id']=str(uuid.uuid1())
        order['ext_orderno']=element.text
        order['partner_id']=globals['partner_id']
        globals['orders'].append(order)
        globals['current_order_id']=order['id']

    if globals['path']==".DELVRY01.IDOC.E1EDL20.E1EDL24.MATNR":
        if not 'positions' in globals:
            globals['positions']=[]

        orderno=stack['E1EDL20'].find("VBELN").text

        pos={}
        pos['id']=str(uuid.uuid1())
        pos['order_id']=globals['current_order_id']
        pos['ext_product_no']=stack['E1EDL24'].find('MATNR').text
        pos['quantity']=stack['E1EDL24'].find('LFIMG').text
        pos['lot_no']=stack['E1EDL24'].find('CHARG').text
        pos['ext_pos']=stack['E1EDL24'].find('POSNR').text
        pos['ext_unit']=stack['E1EDL24'].find('VRKME').text

        globals['positions'].append(pos)
        globals['current_position_id']=pos['id']

    return globals


def execute(context, plugin_context, params):
    if not _validate(params):
        log.create_logger(__name__).warning(f"Missings params")
        return


    content=params['data']['content']
    reader=XmlReader(_inner, context, "DEFAULT", content.encode('utf-8') )
    reader.read()
    print(reader.globals)

