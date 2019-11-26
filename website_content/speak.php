<?php
	session_start();
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
	if (isset($_SESSION['loggued_on_user']) && $_SESSION['loggued_on_user'] != "")
	{
	if (isset($_POST['msg']) && isset($_POST['submit']))
	{
		if ($_POST['msg'] != "" &&  $_POST['submit'] === "OK")
		{
			if (create_proper_folder($folder) != FALSE)
			{
			$new_entry["time"] = time();
			$new_entry["login"] = $_SESSION["loggued_on_user"];
			$new_entry["msg"] = $_POST['msg'];
				if (file_exists($hist))
				{
					if($fd = fopen($hist,"c+"))
					{
						flock($fd, LOCK_SH | LOCK_EX);
						$content = file_get_contents($hist);
						$content = unserialize($content);
						if (isset($content))
							$content[] = $new_entry;
						else
							$content[0] = $new_entry;
					}
				}
				else
					$content[0] = $new_entry;
				$content = serialize($content);
				$content = file_put_contents($hist, $content);
				if (isset($fd))
					flock($fd, LOCK_UN);
			}
		}
	}
}
?>
<script langage="javascript">top.frames['chat'].location = 'chat.php';</script>
<form action="speak.php" name="speak.php" width="80%" method="post">
<input type="text" name="msg" value=""/>
<input type="submit" name="submit" value="OK"/>

