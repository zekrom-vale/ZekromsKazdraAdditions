function core(){
	var xp = document.getElementById("xp").value;
	var fp = document.getElementById("fp").value;
	var x = xp/fp;
	if (x != Math.floor(x)) document.getElementById("r").value = null;
	var off = x/2;
	if (off == Math.floor(off)) document.getElementById("r").value = -fp*(off);
	else document.getElementById("r").value = -fp*Math.ceil(off - 1);
}