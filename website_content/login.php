<?php
	include "auth.php";
	session_start();
	$_SESSION['loggued_on_user'] = "";
	if (isset($_POST) && isset($_POST['login']) && isset($_POST['passwd']))
	{
		if (auth($_POST['login'], $_POST['passwd']) === TRUE)
		{
			$_SESSION['loggued_on_user'] = $_POST['login']; ?>
			<h1>Welcome [<?PHP echo $_SESSION['loggued_on_user'] ?>]</h1>
			<iframe name="chat" src="chat.php" width="100%" height="550px"></iframe>
			<iframe name="speak" src="speak.php" width="100%" height="50px"></iframe>
			<form action="logout.php">
			<input type="submit" name="logout" value="logout"/>
			</form>
			<?php exit;
		}
	}
	echo "ERROR\n";
	exit;
?>
