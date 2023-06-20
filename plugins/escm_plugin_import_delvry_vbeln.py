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

def execute(context, plugin_context, params):
    pass

