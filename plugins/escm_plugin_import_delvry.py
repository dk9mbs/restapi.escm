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
        pass

    if globals['path']=="XXX.DELVRY01.IDOC.E1EDL20.E1EDL24.MATNR":
        pass

def execute(context, plugin_context, params):
    if not _validate(params):
        log.create_logger(__name__).warning(f"Missings params")
        return


    content=params['data']['content']

    globals=dict()
    globals['order']=dict()

    globals={}
    message_type_id="DEFAULT_SAP_SHPCON"

    reader=XmlReader(_inner, context, message_type_id ,globals, content.encode('utf-8'))
    reader.read()

    print(reader.globals)


