function Binary = checkVolts(DataUnit)

 if convertCharsToStrings(DataUnit)=="volts" ||...
        convertCharsToStrings(DataUnit)=="Volts" || ...
           convertCharsToStrings(DataUnit) == "V"
       Binary = true;
 else
     Binary = false;
end