import sys, cgi

'''
if sys.version_info[:2] < (2, 7):
    from ordereddict import OrderedDict
    import simplejson as json_parser
else:
    from collections import OrderedDict
    import json as json_parser

if sys.version_info[:2] < (3, 0):
    text = unicode
    text_types = (unicode, str)
else:
    text = str
    text_types = (str,)
'''
from collections import OrderedDict
import json as json_parser
text = str
text_types = (str,)

class Json2Html:
    def convert(self, json="", table_attributes='border="1"', clubbing=True,nestedtable_layout="vertical",encode=False, escape=True,**kwargs):
        """
            Convert JSON to HTML Table format
        """
        # table attributes such as class, id, data-attr-*, etc.
        # eg: table_attributes = 'class = "table table-bordered sortable"'
        self.table_init_markup = "<table %s>" % table_attributes
        self.clubbing = clubbing
        self.escape = escape
        self.nestedtable_layout = nestedtable_layout
        self.optionalargs = kwargs["optionalargs"]
        #self.equalheaders = True if 'equalheaders' in self.optionalargs else False
        self.customcolumnheaders = self.optionalargs["customheaders"] if 'customheaders' in self.optionalargs else None
        #self.outertable = True   #Indicates the first table is an outer table which needs to be treated seperately

        json_input = None
        
        if not json:
            json_input = {}
        elif type(json) in text_types:
            try:
                json_input = json_parser.loads(json, object_pairs_hook=OrderedDict)
            except ValueError as e:
                #so the string passed here is actually not a json string
                # - let's analyze whether we want to pass on the error or use the string as-is as a text node
                if u"Expecting property name" in text(e):
                    #if this specific json loads error is raised, then the user probably actually wanted to pass json, but made a mistake
                    raise e
                json_input = json
        else:
            json_input = json
           

        '''   
         #Choose the appropriate method based on layout   
        self.convert_object = {
               "vertical": getattr(self,"convert_object_vertical")
              ,"horizantal": getattr(self,"convert_object_horizantal")
        }.get(layout)
        '''
        converted = self.convert_json_node(json_input)
        if encode:
            return converted.encode('ascii', 'xmlcharrefreplace')
        return converted

    def column_headers_from_list_of_dicts_old(self, json_input):
        """
            This method is required to implement clubbing.
            It tries to come up with column headers for your input
        """
        if not json_input \
        or not hasattr(json_input, '__getitem__') \
        or not hasattr(json_input[0], 'keys'):
            return None
        column_headers = json_input[0].keys()

        #Checks if every object has same number of columns
        for entry in json_input:
            if not hasattr(entry, 'keys') \
            or not hasattr(entry, '__iter__') \
            or len(entry.keys()) != len(column_headers) \
            or len(set(entry.keys()).difference(set(column_headers))) > 0:
                #if input was specified as all objects in list has same property names raise exception
                if self.equalheaders:
                    raise ValueError("Invalid Json. Not all objects in list has same property names")    
                return None
            #for header in column_headers:
            #    if header not in entry:
            #        return None
        return column_headers

    def column_headers_from_list_of_dicts(self, json_input):
        """
            This method is required to implement clubbing.
            It tries to come up with column headers for your input
        """
        if not json_input \
        or not hasattr(json_input, '__getitem__') \
        or not hasattr(json_input[0], 'keys'):
            return None
        
        column_headers = []
        #Checks if every entry in list is an object 
        for entry in json_input:
            if not hasattr(entry, 'keys'):
                raise ValueError("Invalid Json. Current version supports only uniform types within list. List cannot mix objects,text,lists")
            for k in entry.keys():
                if k not in column_headers:     
                    column_headers.append(k)
        return column_headers

    def convert_json_node(self, json_input):
        """
            Dispatch JSON input according to the outermost type and process it
            to generate the super awesome HTML format.
            We try to adhere to duck typing such that users can just pass all kinds
            of funky objects to json2html that *behave* like dicts and lists and other
            basic JSON types.
        """
        if type(json_input) in text_types:
            if self.escape:
                return cgi.escape(text(json_input))
            else:
                return text(json_input)
        if hasattr(json_input, 'items'):
            return self.convert_object(json_input)
        if hasattr(json_input, '__iter__') and hasattr(json_input, '__getitem__'):
            return self.convert_list(json_input)
        return text(json_input)

    def __getcustomheader(self,colheader):
        return self.customcolumnheaders[colheader] if colheader in self.customcolumnheaders else colheader

    def __formattablehead(self,headers):
        outputhtml = self.table_init_markup
        if self.customcolumnheaders is not None:
            headers = list(map(self.__getcustomheader,headers))
        outputhtml += '<thead>'
        outputhtml += '<tr><th>' + '</th><th>'.join(headers) + '</th></tr>'
        outputhtml += '</thead>'
        outputhtml += '<tbody>'
        return outputhtml

    '''        
    def __formattablehead(self,headers):
        outputhtml = self.table_init_markup
        if self.customcolumnheaders is not None:
            custom_headers = []
            for colheader in headers:
                custom_headers.append(self.customcolumnheaders[colheader] if colheader in self.customcolumnheaders else colheader)
            headers = custom_headers
        outputhtml += '<thead>'
        outputhtml += '<tr><th>' + '</th><th>'.join(headers) + '</th></tr>'
        outputhtml += '</thead>'
        outputhtml += '<tbody>'
        return outputhtml
    '''
    def convert_list(self, list_input):
        """
            Iterate over the JSON list and process it
            to generate either an HTML table or a HTML list, depending on what's inside.
            If suppose some key has array of objects and all the keys are same,
            instead of creating a new row for each such entry,
            club such values, thus it makes more sense and more readable table.
            @example:
                jsonObject = {
                    "sampleData": [
                        {"a":1, "b":2, "c":3},
                        {"a":5, "b":6, "c":7}
                    ]
                }
                OUTPUT:
                _____________________________
                |               |   |   |   |
                |               | a | c | b |
                |   sampleData  |---|---|---|
                |               | 1 | 3 | 2 |
                |               | 5 | 7 | 6 |
                -----------------------------
            @contributed by: @muellermichel
        """
        if not list_input:
            return ""
        #converted_output = ""
        column_headers = None
        if self.clubbing:
            column_headers = self.column_headers_from_list_of_dicts(list_input) 
        if column_headers is not None:
            converted_output = self.__formattablehead(column_headers)
            #if self.customcolumnheaders is None:
               # print("normal")
                #converted_output = self.__formattablehead(column_headers)
            #else:
              #  print("custom")
                #custom_headers = []
               # for colheader in column_headers:
                    #custom_headers.append(self.customcolumnheaders[colheader] if colheader in self.customcolumnheaders else colheader)
                    #converted_output = self.__formattablehead(custom_headers)
            for list_entry in list_input:
                converted_output += '<tr><td>'
                colvalues=[]
                for column_header in column_headers:
                    if column_header in list_entry:
                        colvalues.append(self.convert_json_node(list_entry[column_header]))
                    else:
                        colvalues.append(" ")                              
                converted_output += '</td><td>'.join(colvalues)
                converted_output += '</td></tr>'
            converted_output += '</tbody>'
            converted_output += '</table>'
            return converted_output

        #so you don't want or need clubbing , let's fall back to a basic list here...
        converted_output = '<ul><li>'
        converted_output += '</li><li>'.join([self.convert_json_node(child) for child in list_input])
        converted_output += '</li></ul>'
        return converted_output

    def convert_object(self, json_input):
        """
            Iterate over the JSON object and process it
            to generate the super awesome HTML Table format
        """
        if not json_input:
            return "" #avoid empty tables

        if self.nestedtable_layout == "vertical":    
            converted_output = self.table_init_markup + "<tr>"
            converted_output += "</tr><tr>".join([
                "<th>%s</th><td>%s</td>" %(
                    self.convert_json_node(self.__getcustomheader(k)),
                    self.convert_json_node(v)
                )
                for k, v in json_input.items()
            ])
            converted_output += '</tr></table>'
        else:
            converted_output = self.__formattablehead(json_input.keys()) 
            converted_output += '<tr><td>'
            converted_output += '</td><td>'.join([self.convert_json_node(value) for value in
                                                         json_input.values()])
            converted_output += '</td></tr></tbody></table>'
            
        return converted_output