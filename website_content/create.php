<?php
	$folder = "./private";
	$passwords = "$folder/passwd";
	function error_print()
	{
		echo "ERROR\n";
		exit;
	}

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
	if (!isset($_POST['login']) || !isset($_POST['submit']) || !isset($_POST['passwd']))
		error_print();
	if ($_POST['login'] === "" || $_POST['passwd'] === "" || $_POST['submit'] != "OK")
		error_print();
	if (create_proper_folder($folder) === FALSE)
		error_print();
	$new_entry["passwd"] = hash("whirlpool",  $_POST['passwd']);
	$new_entry["login"] = $_POST['login'];
	if (file_exists($passwords))
	{
		if(!($content = file_get_contents($passwords)))
			error_print();
		$content = unserialize($content);
		if (isset($content) && !empty($content))
		{
			foreach($content as $entries)
			{
				if (!isset($entries["passwd"]) || !isset($entries["login"]))
					error_print();
				if ($entries["login"] === $_POST['login'])
					error_print();
			}
			$content[] = $new_entry;
		}
		else
			$content[0] = $new_entry;
	}
	else
		$content[0] = $new_entry;
	$content = serialize($content);
	if (!file_put_contents($passwords, $content))
		error_print();
	header("Location:index.html");
	echo "OK\n";
?>
