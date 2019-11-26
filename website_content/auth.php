<?php

	function auth($login, $passwd)
	{
		$folder = "./private";
		$passwords = "$folder/passwd";
		$passwd =  hash("whirlpool",  $passwd);
		if (!file_exists($folder) || !file_exists($passwords))
			return FALSE;
		if ($login === "" || $passwd === "")
			return FALSE;
 		if(!($content = file_get_contents($passwords)))
			return FALSE;
		$content = unserialize($content);
		if(empty($content))
			return FALSE;
		foreach($content as $entries)
		{
			if (!isset($entries["passwd"]) || !isset($entries["login"]))
				return FALSE;
			if ($entries["login"] === $login
			&& ($entries["passwd"] === $passwd))
				return TRUE;
		}
		return FALSE;
	}
?>
