<?php
	date_default_timezone_set("Europe/Paris");
	$folder = "./private";
	$hist = "$folder/chat";
	function create_proper_folder($folder)
	{
			if (!$folder || $folder == "")
					return FALSE;
			if (file_exists($folder))
					return TRUE;
			if((@mkdir($folder, 0777, true)))
					return TRUE;
			return FALSE;
	}

	if (create_proper_folder($folder) != FALSE)
	{
		if (file_exists($hist))
		{
			if($fd = fopen($hist,"r"))
			{
				flock($fd, LOCK_SH);
				$content = file_get_contents($hist);
				$content = unserialize($content);
				if (!empty($content))
				{
					foreach ($content as $line)
					{
						if (isset($line["time"]) && isset($line["msg"]) && isset($line["login"]))
						{
							echo date("[H:i] ", $line["time"]);
							echo "<b>".$line["login"]."</b>: ";
							echo $line["msg"]."<br />\n";
						}
					}
				}
				flock($fd, LOCK_UN);
			}
		}
	}
?>
