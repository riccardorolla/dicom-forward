$conf = Read-Properties $PSScriptRoot\fwdsr.properties
 
start-dicomserver -Port $conf.port -AET $conf.AET  -Environment $conf  -onCStoreRequest {
	param($request,$file,$association,$env) 

	$header = $file | read-dicom 
	Try {
	 $cc=$header.AccessionNumber.Split("-")
	 $prefix=($cc[0] + "-" + $cc[1])

		$sendStatus = (send-dicom -AET $association.CallingAE -SOPClassProvider $env[$prefix] -DicomFile $file).Status
		Write-EventLog -LogName "Application" -Source "Forward Dicom" -EventID 1200 -EntryType Information -Message (
			"send AccessionNumber:" + $header.AccessionNumber +  "`n" +
			"StudyInstanceUID:"+ $header.StudyInstanceUID + "`n" +
			"SOPInstanceUID:" + $header.SOPInstanceUID +  "`n" +
		    " to " + $env[$prefix] +
			" with Status " + $sendStatus)

		$sendStatus		
		
	}
	Catch
		{
			 
			save-dicom -Filename ($env.error_dir + '\' + $header.StudyInstanceUID + '\' + $header.SOPInstanceUID)  -DicomFile $file
				[Dicom.Network.DicomStatus]::Success
			Write-EventLog -LogName "Application" -Source "Forward Dicom" -EventID 1201 -EntryType Error -Message ("Save filename:" +  ($env.error_dir + '\' + $header.StudyInstanceUID + '\' + $header.SOPInstanceUID))
			}
		
}
  
	  

