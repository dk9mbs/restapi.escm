DELETE FROM api_process_log WHERE event_handler_id IN (SELECT id FROM api_event_handler WHERE solution_id=10004);
DELETE FROM api_group_permission WHERE solution_id=10004;
DELETE FROM api_user_group WHERE solution_id=10004;
DELETE FROM api_session WHERE user_id IN(100040001);
DELETE FROM api_user WHERE solution_id=10004;
DELETE FROM api_group WHERE solution_id=10004;
DELETE FROM api_event_handler WHERE solution_id=10004;
DELETE FROM api_table_view where solution_id=10004;
DELETE FROM api_ui_app_nav_item WHERE solution_id=10004;

/*
Tables
*/
DROP TABLE IF EXISTS escm_order_position;
DROP TABLE IF EXISTS escm_order;


CREATE TABLE IF NOT EXISTS escm_order (
    id varchar(50) NOT NULL,
    ext_order_no varchar(50),
    message_type varchar(50),
    document_type varchar(50),
    partner_id varchar(50),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS escm_order_position (
    id varchar(50) NOT NULL,
    order_id varchar(50),
    ext_product_no varchar(50),
    quantity decimal(6,2),
    lot_no varchar(50),
    ext_pos varchar(50),
    ext_unit varchar(50),
    PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040001,'escm_order','escm_order','id','string','ext_order_no',0,10004);

INSERT IGNORE INTO api_table(id,alias,table_name,id_field_name,id_field_type,desc_field_name,enable_audit_log,solution_id)
    VALUES
    (100040002,'escm_order_position','escm_order_position','id','string','ext_product_no',0,10004);



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
    VALUES (100040002, 'api_exec_inline_code','.DELVRY01.IDOC.EDI_DC40','xml_read','before',100,10004,0,0, '
import uuid
import xml.etree.ElementTree as ET

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

if not \'orders\' in globals:
    globals[\'orders\']=[]

order={}
order[\'document_type\']=element.find("IDOCTYPE").text
order[\'message_type\']=element.find("MESTYP").text

globals[\'orders\'].append(order)');



INSERT IGNORE INTO api_event_handler (id, plugin_module_name,publisher,event,type,sorting,solution_id,run_async, run_queue, inline_code)
    VALUES (100040003, 'api_exec_inline_code','.DELVRY01.IDOC.E1EDL20','xml_read','before',100,10004,0,0, '
import uuid
import xml.etree.ElementTree as ET

globals=params[\'globals\']
element=ET.XML(params[\'element\'])

if not \'orders\' in globals:
    globals[\'orders\']=[]
order={}
order[\'id\']=str(uuid.uuid1())
order[\'ext_order_no\']=element.text
order[\'partner_id\']=globals[\'partner_id\']

globals[\'orders\'].append(order)
globals[\'current_order_id\']=order[\'id\']');



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



