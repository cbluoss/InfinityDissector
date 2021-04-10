infinity_protocol = Proto("Infinity",  "Infinity Network Protocol")

message_timestamp = ProtoField.int32("infinity.message_timestamp", "messageTimestamp", base.DEC)
message_length = ProtoField.int16("infinity.message_length", "messageLength", base.DEC)
message_device = ProtoField.string("infinity.device", "device", base.ASCII)
message_alert = ProtoField.string("infinity.alert", "alert", base.ASCII)

RRsys = ProtoField.int16("infinity.RRsys", "RRsys", base.DEC)
RRdia = ProtoField.int16("infinity.RRdia", "RRdia", base.DEC)
RRmad = ProtoField.int16("infinity.RRmad", "RRmad", base.DEC)

sPO2 = ProtoField.int16("infinity.sPO2", "sPO2", base.DEC)
sPO2_P = ProtoField.int16("infinity.sPO2_P", "sPO2 Puls", base.DEC)

PatientName = ProtoField.string("infinity.PatientName", "Patient Name", base.ASCII)
infinity_protocol.fields = {message_timestamp, message_length, message_device, message_alert, RRsys, RRdia, RRmad, sPO2, sPO2_P, PatientName}

function infinity_protocol.dissector(buffer, pinfo, tree)
  length = buffer:len()
  if length == 0 then return end

  pinfo.cols.protocol = infinity_protocol.name

  local subtree = tree:add(infinity_protocol, buffer(), "infinity Protocol Data")

  subtree:add(message_timestamp, buffer(0x14,4))
  subtree:add(message_length, length)

  if length == 660 then 
  	-- local device_str = ""
  	-- local device = buffer:bytes(0x61,16)
  	-- for i, _ in ipairs(device) do
  	-- 	device_str = device_str .. device[i]
  	-- end

  	subtree:add(message_device, buffer:range(0x60,16):ustring())
  	subtree:add(message_alert, buffer:range(0xAE,32):ustring())
  	subtree:add(PatientName, buffer:range(0x24,48):ustring())

  end


  if length > 1000 then 
  	subtree:add(RRsys, buffer(0x0147,1)) 
  	subtree:add(RRdia, buffer(0x016B,1)) 
  	subtree:add(RRmad, buffer(0x018F,1)) 

   	subtree:add(sPO2, buffer(0x00FF,1)) 
  	subtree:add(sPO2_P, buffer(0x0123,1)) 
  end


end

local udp_port = DissectorTable.get("udp.port")
udp_port:add(2050, infinity_protocol)
