infinity_protocol = Proto("Infinity",  "Infinity Network Protocol")
infinity_protocol.fields = {}

-- What we know about the protocol so far:
-- * a 18(?) Byte header with a message_timestamp followed for
-- * 660 Byte broadcasts used for alarm and status messages e.g. "ECG electrodes removed"
-- * >1000 Byte broadcast depending on the current device configuration send every second  with all current datapoints
--   * 36 Bytes for each of most datapoints (including lower/upper alarm thresholds, the measured value)


-- Common packet fields:
packet_length = ProtoField.int16("infinity.packet.length", "Packet length", base.DEC)
infinity_protocol.fields[#infinity_protocol.fields+1]=packet_length
packet_timestamp = ProtoField.int32("infinity.packet.timestamp", "Packet timestamp", base.DEC)  -- 0x14,4
infinity_protocol.fields[#infinity_protocol.fields+1]=packet_timestamp

-- Message packet fields:
is_message = ProtoField.bool("infinity.packet.message", "Is Message")
infinity_protocol.fields[#infinity_protocol.fields+1]=is_message
message_device = ProtoField.string("infinity.message.device", "Device", base.ASCII)             -- 0x60,16
infinity_protocol.fields[#infinity_protocol.fields+1]=message_device
message_alert = ProtoField.string("infinity.message.alert", "Alert", base.ASCII)                -- 0xAE,32
infinity_protocol.fields[#infinity_protocol.fields+1]=message_alert

patient_name = ProtoField.string("infinity.patient.name", "Patient Name", base.ASCII)           -- 0x24,48
infinity_protocol.fields[#infinity_protocol.fields+1]=patient_name

-- Data packet fields:
-- (basic) Alarm tresholds are usually -2/+2 bytes  relative to the measured value
is_data = ProtoField.bool("infinity.packet.data", "Is Data")
infinity_protocol.fields[#infinity_protocol.fields+1]=is_data

ecg_respiratory_rate = ProtoField.int8("infinity.data.ecg.respiratory_rate", "Respiratory Rate (ECG)", base.DEC)  -- 0x00DB
infinity_protocol.fields[#infinity_protocol.fields+1]=ecg_respiratory_rate

spo2 = ProtoField.int8("infinity.data.spo2", "sPO2", base.DEC)                                      -- 0x01FF
infinity_protocol.fields[#infinity_protocol.fields+1]=spo2
spo2_pulse = ProtoField.int8("infinity.data.spo2.pulse", "sPO2 Pulse", base.DEC)                    -- 0x0123
infinity_protocol.fields[#infinity_protocol.fields+1]=spo2_pulse

nibp_sys = ProtoField.int8("infinity.data.nibp.sys", "NIBP (Systolic)", base.DEC)                   -- 0x0147
infinity_protocol.fields[#infinity_protocol.fields+1]=nibp_sys
nibp_dia = ProtoField.int8("infinity.data.nibp.dia", "NIBP (Diastolic)", base.DEC)                  -- 0x016B
infinity_protocol.fields[#infinity_protocol.fields+1]=nibp_dia
nibp_map = ProtoField.int8("infinity.data.nibp.map", "NIBP (MAP)", base.DEC)                        -- 0x018F
infinity_protocol.fields[#infinity_protocol.fields+1]=nibp_map

temperature = ProtoField.int16("infinity.data.temperature", "Temperature (in Celsius *10)", base.DEC) -- 0x00B6,2
infinity_protocol.fields[#infinity_protocol.fields+1]=temperature

RRsys = ProtoField.int16("infinity.RRsys", "RRsys", base.DEC)
RRdia = ProtoField.int16("infinity.RRdia", "RRdia", base.DEC)
RRmad = ProtoField.int16("infinity.RRmad", "RRmad", base.DEC)
NIBPsys = ProtoField.string("infinity.nibp.sys", "NIBP Systolic", base.ASCII)

sPO2 = ProtoField.int16("infinity.sPO2", "sPO2", base.DEC)
sPO2_P = ProtoField.int16("infinity.sPO2_P", "sPO2 Puls", base.DEC)

infinity_protocol.fields = {RRsys, RRdia, RRmad, sPO2, sPO2_P, NIBPsys }

function infinity_protocol.dissector(buffer, pinfo, tree)

  length = buffer:len()
  if length == 0 then return end

  pinfo.cols.protocol = infinity_protocol.name

  local subtree = tree:add(infinity_protocol, buffer(), "infinity Protocol Data")

  subtree:add(packet_timestamp, buffer(0x14,4))
  subtree:add(packet_length, length)

  if length == 660 then 
    subtree:add(is_message, true)
  	subtree:add(message_device, buffer:range(0x60,16):ustring())
  	subtree:add(message_alert, buffer:range(0xAE,32):ustring())
  	subtree:add(patient_name, buffer:range(0x24,48):ustring())

  end


  if length > 1000 then 
    subtree:add(is_data, true)
  	subtree:add(ecg_respiratory_rate, buffer(0x00DB,1)) 
    subtree:add(spo2, buffer(0x01FF,1)) 
    subtree:add(spo2_pulse, buffer(0x0123,1)) 
    subtree:add(nibp_sys, buffer(0x0147,1)) 
    subtree:add(nibp_dia, buffer(0x016B,1)) 
    subtree:add(nibp_map, buffer(0x018F,1)) 
    subtree:add(temperature, buffer(0x00B6,2)) 



  end


end

local udp_port = DissectorTable.get("udp.port")
udp_port:add(2050, infinity_protocol)
