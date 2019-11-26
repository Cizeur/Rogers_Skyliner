<?php
	$folder = "./private";
	$passwords = "$folder/passwd";
	function error_print()
	{
		echo "ERROR\n";
		exit;
	}
	if (!file_exists($folder) || !file_exists($passwords))
		error_print();
	if (!isset($_POST['login']) || !isset($_POST['submit']) || !isset($_POST['oldpw']) || !isset($_POST['newpw']))
		error_print();
	if ($_POST['login'] === "" || $_POST['oldpw'] === "" || $_POST['newpw'] === ""|| $_POST['submit'] != "OK")
		error_print();
	$newpw = hash("whirlpool",  $_POST['newpw']);
	$oldpw = hash("whirlpool",  $_POST['oldpw']);
	$login = $_POST['login'];
	$content = file_get_contents($passwords);
	$content = unserialize($content);
	if(!isset($content) || empty($content))
		error_print();
	foreach($content as $key => $entries)
	{
		if (!isset($entries["passwd"]) || !isset($entries["login"]))
			error_print();
		if ($entries["login"] === $login
		&& ($entries["passwd"] === $oldpw))
		{
			$content[$key]["passwd"] = $newpw;
			$content = serialize($content);
			if (!file_put_contents($passwords, $content))
				error_print();
			header("Location:index.html");
			echo "OK\n";
			return (0);
		}
	}
	error_print();
?>
