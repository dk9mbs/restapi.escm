DELETE FROM api_process_log WHERE event_handler_id IN (SELECT id FROM api_event_handler WHERE solution_id=10004);
DELETE FROM api_group_permission WHERE solution_id=10004;
DELETE FROM api_user_group WHERE solution_id=10004;
DELETE FROM api_session WHERE user_id IN(100040001);
DELETE FROM api_user WHERE solution_id=10004;
DELETE FROM api_group WHERE solution_id=10004;
DELETE FROM api_event_handler WHERE solution_id=10004;
DELETE FROM api_table_view where solution_id=10004;
DELETE FROM api_ui_app_nav_item WHERE solution_id=10004;
UPDATE api_table SET desc_field_name='ext_document_no' WHERE id=100040003;

/*
Tables
*/
DROP TABLE IF EXISTS escm_order_position_lot;
DROP TABLE IF EXISTS escm_order_position;
DROP TABLE IF EXISTS escm_order;
DROP TABLE IF EXISTS escm_message;
DROP TABLE IF EXISTS escm_message_exchange;
DROP TABLE IF EXISTS escm_message_type;
DROP TABLE IF EXISTS escm_partner;

CREATE TABLE IF NOT EXISTS escm_partner (
    id varchar(50) NOT NULL,
    name varchar(250) NOT NULL,
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO escm_partner (id, name) VALUE('DEFAULT','Default partner');

CREATE TABLE IF NOT EXISTS escm_message_exchange (
    id varchar(50) NOT NULL,
    name varchar(250) NOT NULL,
    partner_id varchar(50),
    process nvarchar(250) NOT NULL,
    test_text text NULL,
    PRIMARY KEY(id),
    FOREIGN KEY(partner_id) REFERENCES escm_partner(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO escm_message_exchange (id, name, test_text, process, partner_id) 
    VALUE
        ('DEFAULT_SAP_SHPCON','Warenausgang Rückmeldung','<MESTYP>SHPCON</MESTYP>','SAP_SHPCON', 'DEFAULT');

INSERT IGNORE INTO escm_message_exchange (id, name, test_text, process, partner_id) 
    VALUE
        ('DEFAULT_SAP_DESADV','Liefer Avis','<IDOCTYP>DELVRY0','SAP_DESADV', 'DEFAULT');

CREATE TABLE IF NOT EXISTS escm_message (
    id varchar(50) NOT NULL,
    file_name varchar(250),
    ext_message_type varchar(50),
    message_exchange_id varchar(50),
    ext_document_type varchar(50),
    document_type_id varchar(50),
    ext_document_no varchar(50),
    ext_direction varchar(50),
    direction_id varchar(50),
    partner_id varchar(50),
    PRIMARY KEY(id),
    FOREIGN KEY(message_exchange_id) REFERENCES escm_message_exchange(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS escm_order (
    id varchar(50) NOT NULL,
    message_id varchar(50),
    ext_order_no varchar(50),
    message_exchange_id varchar(50),
    net_weight decimal(10,2),
    gross_weight decimal(10,2),
    ext_weight_unit varchar(50),
    weight_unit_id varchar(50),
    PRIMARY KEY(id),
    FOREIGN KEY(message_id) REFERENCES escm_message(id),
    FOREIGN KEY(message_exchange_id) REFERENCES escm_message_exchange(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS escm_order_position (
    id varchar(50) NOT NULL,
    order_id varchar(50),
    ext_product_no varchar(50),
    product_id varchar(50),
    quantity decimal(10,4),
    ext_unit varchar(50),
    unit_id varchar(50),
    gross_weight decimal(10,4),
    net_weight decimal(10,4),
    ext_weight_unit varchar(50),
    weight_unit_id varchar(50),
    ext_pos varchar(50),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS escm_order_position_lot (
    id varchar(50) NOT NULL,
    order_position_id varchar(50),
    lot_no varchar(50),
    quantity decimal(10,4),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040001,'escm_order','escm_order','id','string','ext_order_no',0,10004);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040002,'escm_order_position','escm_order_position','id','string','ext_product_no',0,10004);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040003,'escm_message','escm_message','id','string','ext_document_no',0,10004);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040004,'escm_order_position_lot','escm_order_position_lot','id','string','lot_no',0,10004);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040005,'escm_message_exchange','escm_message_exchange','id','string','name',0,10004);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040006,'escm_partner','escm_partner','id','string','name',0,10004);

/*
Meta Data
*/
INSERT IGNORE INTO api_solution(id,name) VALUES (10004, 'ESCM');
INSERT IGNORE INTO api_user (id,username,password,is_admin,disabled,solution_id) VALUES (100040001,'escm_admin','password',0,0,10004);
INSERT IGNORE INTO api_group(id,groupname,solution_id) VALUES (100040001,'escm',10004);
INSERT IGNORE INTO api_user_group(user_id,group_id,solution_id) VALUES (100040001,100040001,10004);


INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue)
    VALUES (100040001, 'plugins.escm_plugin_import_delvry','textfileimport_desadv','post','before',100,10004,0,0);



INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040002, 'api_exec_inline_code','.DELVRY.IDOC.EDI_DC40','SAP_SHPCON','before',100,10004,0,0, '
"""
Collect order data in the control dict
"""
import xml.etree.ElementTree as ET
import uuid

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

globals[\'message\']={}
globals[\'message\'][\'id\']=str(uuid.uuid1())
globals[\'message\'][\'document_type\']=element.find("IDOCTYP").text
globals[\'message\'][\'message_type\']=element.find("MESTYP").text
globals[\'message\'][\'direction\']=element.find("DIRECT").text
');


INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040003, 'api_exec_inline_code','.DELVRY.IDOC.EDI_DC40','SAP_SHPCON','after',100,10004,0,0, '
"""
Save the message information
"""
import xml.etree.ElementTree as ET

from shared.model import escm_message

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

msg=escm_message()
msg.id.value=globals[\'message\'][\'id\']
msg.ext_document_type.value=globals[\'message\'][\'document_type\']
msg.ext_message_type.value=globals[\'message\'][\'message_type\']
msg.ext_direction.value=globals[\'message\'][\'direction\']
msg.message_exchange_id.value=globals[\'message_exchange_id\']
msg.file_name.value=globals[\'file_name\']
msg.insert(context)
');


INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040004, 'api_exec_inline_code','.DELVRY.IDOC.E1EDL20','SAP_SHPCON','before',100,10004,0,0, '
"""
Collect orderhead informations for escm_order
"""
import xml.etree.ElementTree as ET
import uuid

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

globals[\'order\']={}

globals[\'order\'][\'id\']=str(uuid.uuid1())
globals[\'order\'][\'ext_order_no\']=element.find("VBELN").text
globals[\'order\'][\'net_weight\']=element.find("BTGEW").text
globals[\'order\'][\'gross_weight\']=element.find("NTGEW").text
globals[\'order\'][\'weight_unit\']=element.find("GEWEI").text
');

INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040005, 'api_exec_inline_code','.DELVRY.IDOC.E1EDL20','SAP_SHPCON','after',100,10004,0,0, '
"""
Save the order in escm_orders on closed tag
"""
from shared.model import escm_order
import xml.etree.ElementTree as ET

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

order=escm_order.objects(context).select().where(escm_order.ext_order_no==globals[\'order\'][\'ext_order_no\']).to_entity()
if order==None:
    order=escm_order()
    order.id.value=str(globals[\'order\'][\'id\'])
    order.ext_order_no.value=globals[\'order\'][\'ext_order_no\']
    order.message_id.value=globals[\'message\'][\'id\']
    order.net_weight.value=globals[\'order\'][\'net_weight\']
    order.gross_weight.value=globals[\'order\'][\'gross_weight\']
    order.ext_weight_unit.value=globals[\'order\'][\'weight_unit\']
    order.message_exchange_id.value=globals[\'message_exchange_id\']
    order.insert(context)
else:
    raise(Exception(\'Beleg bereits vorhanden!!!\'))
');


/* Positions */
INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040006, 'api_exec_inline_code','.DELVRY.IDOC.E1EDL20.E1EDL24','SAP_SHPCON','before',100,10004,0,0, '
"""
Collect orderhead informations for escm_order
"""
import xml.etree.ElementTree as ET
import uuid

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

globals[\'position\']={}
globals[\'lot\']={}

globals[\'position\'][\'id\']=str(uuid.uuid1())
globals[\'position\'][\'order_id\']=globals[\'order\'][\'id\']
globals[\'position\'][\'ext_pos_no\']=element.find("POSNR").text
globals[\'position\'][\'ext_product_no\']=element.find("MATNR").text
globals[\'position\'][\'quantity\']=element.find("LFIMG").text
globals[\'position\'][\'gross_weight\']=element.find("VRKME").text
globals[\'position\'][\'net_weight\']=element.find("NTGEW").text
globals[\'position\'][\'gross_weight\']=element.find("BRGEW").text
globals[\'position\'][\'weight_unit\']=element.find("GEWEI").text
globals[\'position\'][\'unit\']=element.find("VRKME").text

globals[\'lot\'][\'id\']=str(uuid.uuid1())
globals[\'lot\'][\'order_position_id\']=globals[\'position\'][\'id\']
globals[\'lot\'][\'lot_no\']=element.find("CHARG").text
globals[\'lot\'][\'quantity\']=element.find("LFIMG").text
globals[\'lot\'][\'unit\']=element.find("VRKME").text

');


INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040007, 'api_exec_inline_code','.DELVRY.IDOC.E1EDL20.E1EDL24','SAP_SHPCON','after',100,10004,0,0, '
"""
Save Position informations for escm_order
"""
import xml.etree.ElementTree as ET
from shared.model import *

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

if \'position\' in globals:
    pos=escm_order_position()
    pos.id.value=globals[\'position\'][\'id\']
    pos.order_id.value=globals[\'position\'][\'order_id\']
    pos.ext_pos.value=globals[\'position\'][\'ext_pos_no\']
    pos.quantity.value=globals[\'position\'][\'quantity\']
    pos.ext_unit.value=globals[\'position\'][\'unit\']
    pos.gross_weight.value=globals[\'position\'][\'gross_weight\']
    pos.net_weight.value=globals[\'position\'][\'net_weight\']
    pos.ext_weight_unit.value=globals[\'position\'][\'weight_unit\']
    pos.ext_product_no.value=globals[\'position\'][\'ext_product_no\']

pos.insert(context)

if \'lot\' in globals:
    lot=escm_order_position_lot()
    lot.id.value=globals[\'lot\'][\'id\']
    lot.order_position_id.value=globals[\'position\'][\'id\']
    lot.lot_no.value=globals[\'lot\'][\'lot_no\']
    lot.quantity.value=globals[\'lot\'][\'quantity\']
    lot.insert(context)
');



/*

DESADV

*/

INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040008, 'api_exec_inline_code','.DELVRY.IDOC.EDI_DC40','SAP_DESADV','before',100,10004,0,0, '
"""
Collect order data in the control dict
"""
import xml.etree.ElementTree as ET
import uuid
from shared.model import escm_message

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

globals[\'message\']={}
globals[\'message\'][\'id\']=str(uuid.uuid1())

msg=escm_message()
msg.id.value=globals[\'message\'][\'id\']
msg.ext_document_type.value=element.find("IDOCTYP").text
msg.ext_message_type.value=element.find("MESTYP").text
msg.ext_direction.value=element.find("DIRECT").text
msg.message_exchange_id.value=globals[\'message_exchange_id\']
msg.file_name.value=globals[\'file_name\']
msg.ext_document_no.value=element.find("DOCNUM").text
msg.insert(context)
');



INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040009, 'api_exec_inline_code','.DELVRY.IDOC.E1EDL20','SAP_DESADV','before',100,10004,0,0, '
"""
Collect orderhead informations for escm_order
"""
import xml.etree.ElementTree as ET
import uuid
from shared.model import escm_order

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

globals[\'order\']={}

globals[\'order\'][\'id\']=str(uuid.uuid1())

order=escm_order.objects(context).select().where(escm_order.ext_order_no==element.find("VBELN").text).where(escm_order.message_exchange_id=="DEFAULT_SAP_DESADV").to_entity()
if order==None:
    order=escm_order()
    order.id.value=str(globals[\'order\'][\'id\'])
    order.ext_order_no.value=element.find("VBELN").text
    order.message_id.value=globals[\'message\'][\'id\']
    order.net_weight.value=element.find("NTGEW").text
    order.gross_weight.value=element.find("BTGEW").text
    order.ext_weight_unit.value=element.find("GEWEI").text
    order.message_exchange_id.value=globals[\'message_exchange_id\']
    order.insert(context)
else:
    raise(Exception(\'Beleg bereits vorhanden!!!\'))
');

/*

*/
INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040010, 'api_exec_inline_code','.DELVRY.IDOC.E1EDL20.E1EDL24','SAP_DESADV','before',100,10004,0,0, '
"""
Collect orderhead informations for escm_order
"""
import xml.etree.ElementTree as ET
import uuid
from shared.model import *

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

globals[\'position\']={}
globals[\'lot\']={}

globals[\'position\'][\'id\']=str(uuid.uuid1())
globals[\'position\'][\'order_id\']=globals[\'order\'][\'id\']
globals[\'lot\'][\'id\']=str(uuid.uuid1())

if \'position\' in globals:
    pos=escm_order_position()
    pos.id.value=globals[\'position\'][\'id\']
    pos.order_id.value=globals[\'order\'][\'id\']

    pos.ext_pos.value=element.find("POSNR").text
    pos.quantity.value=element.find("LFIMG").text
    pos.ext_unit.value=element.find("VRKME").text
    pos.gross_weight.value=element.find("BRGEW").text
    pos.net_weight.value=element.find("NTGEW").text
    pos.ext_weight_unit.value=element.find("GEWEI").text
    pos.ext_product_no.value=element.find("MATNR").text
    pos.insert(context)

if not element.find("CHARG")==None:
    lot=escm_order_position_lot()
    lot.id.value=globals[\'lot\'][\'id\']
    lot.order_position_id.value=globals[\'position\'][\'id\']
    lot.lot_no.value=element.find("CHARG").text
    lot.quantity.value=element.find("LFIMG").text
    lot.insert(context)
');










/*


call api_proc_create_table_field_instance(100030001,10, 'id','ID', 'string',1,'{"disabled": true}', @out_value);
call api_proc_create_table_field_instance(100030001,20,'auftragskonto','Auftragskonto','string',1,'{"disabled": true}', @out_value);

INSERT IGNORE INTO api_ui_app (id, name,description,home_url,solution_id)
VALUES (
100040001,'100040001','ESCM','/ui/v1.0/data/view/bank_item/default?app_id=100030001',10003);

INSERT IGNORE INTO api_ui_app_nav_item(id, app_id,name,url,type_id,solution_id) VALUES (
100030001,100030001,'Buchungen','/ui/v1.0/data/view/bank_item/default',1,10003);

INSERT IGNORE INTO api_group_permission (group_id,table_id,mode_create,mode_read,mode_update,mode_delete,solution_id)
    VALUES
    (100030001,100030001,-1,-1,-1,-1,10003);
*/


/*
INSERT IGNORE INTO api_event_handler(id,plugin_module_name,publisher,event,type,solution_id,run_async)
VALUES (100030002,'plugins.bank_plugin_set_category','$timer_every_ten_minutes','execute','after',10003,-1);


INSERT IGNORE INTO api_table_view (id,type_id,name,table_id,id_field_name,solution_id,fetch_xml) VALUES (
100030001,'LISTVIEW','default',100030001,'id',10003,'<restapi type="select">
    <table name="bank_item" alias="i"/>
    <filter type="or">
        <condition field="beguenstigter_zahlungspflichtiger" alias="i" value="$$query$$" operator="$$operator$$"/>
    </filter>
    <orderby>
        <field name="valutadatum" alias="i" sort="DESC"/>
    </orderby>
    <select>
        <field name="category_id" table_alias="i" header="Kategorie"/>
        <field name="valutadatum" table_alias="i" header="Valutadatum"/>
        <field name="betrag" table_alias="i" header="Betrag"/>
        <field name="waehrung" table_alias="i" header="Wkz"/>
        <field name="auftragskonto" table_alias="i" header="Auftragskonto"/>
        <field name="verwendungszweck" table_alias="i" header="Verwendungszweck"/>
        <field name="info" table_alias="i" header="Info"/>
        <field name="id" table_alias="i" header="ID"/>
    </select>
</restapi>');

*/

/* out_data_formatter */
/*
INSERT IGNORE INTO api_data_formatter(id,name, table_id,type_id) VALUES (100030001,'x',100030001,2);

UPDATE api_data_formatter SET
name='bank_csvmt940',
line_separator='@n',
content_disposition='inline',
file_name='bank_csmmt940.csv',
mime_type='application/csv',
template_header='"Auftragskonto";"Buchungstag";"Valutadatum";"Buchungstext";"Verwendungszweck";"Beguenstigter/Zahlungspflichtiger";"Kontonummer";"BLZ";"Betrag";"Waehrung";"Info";"Kategorie";"Konto";"Monat";"Jahr"',
template_line='"{{ data[\'auftragskonto\'] }}";"{{ format_date( data[\'buchungstag\'],\'%d.%m.%Y\') }}";"{{ format_date( data[\'valutadatum\'],\'%d.%m.%Y\') }}";"{{ data[\'buchungstext\'] }}";"{{ data[\'verwendungszweck\'] }}";"{{ data[\'beguenstigter_zahlungspflichtiger\'] }}";"{{ data[\'kontonummer\'] }}";"{{ data[\'blz\'] }}";{{ replace(data[\'betrag\'],\'.\',\',\') }};"{{ data[\'waehrung\'] }}";"{{ data[\'info\'] }}";"{{ data[\'category_id\'] }}";"{{ data[\'account_id\'] }}";"{{ format_date( data[\'valutadatum\'],\'%m\') }}";"{{ format_date( data[\'valutadatum\'],\'%Y\') }}"',
template_footer=null
WHERE id=100030001 AND provider_id='MANUFACTURER';
*/



