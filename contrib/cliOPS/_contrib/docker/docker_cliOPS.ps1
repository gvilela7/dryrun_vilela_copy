if (!(docker images -q myimage:mytag 2> $null)) { 
  # do something
}