# This file was generated, do not modify it. # hide
#hideall
team = [
  (name="Jane Doe", title="CEO & Founder", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com"),
  (name="Mike Ross", title="Art Director", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com"),
  (name="John Doe", title="Designer", vitae="Phasellus eget enim eu lectus faucibus vestibulum", email="example@example.com")
  ]

"@@cards @@row" |> println
for person in team
  """
  @@column
    \\card{$(person.name)}{$(person.title)}{$(person.vitae)}{$(person.email)}
  @@
  """ |> println
end
println("@@ @@") # end of cards + row

raw"""
~~~
<style>
.column {
  float:left;
  width:30%;
  margin-bottom:16px;
  padding:0 8px;
}
@media (max-width:62rem) {
  .column {
    width:45%;
    display:block;
  }
}
@media (max-width:30rem){
  .column {
    width:95%;
    display:block;
  }
}
.card{
  box-shadow: 0 4px 8px 0 rgba(0,0,0,0.2);
}
.card img {
  padding-left:0;
  width: 100%;
}
.container {
  padding: 0 16px;
}
.container::after, .row::after{
  content:"";
  clear:both;
  display:table;
}
.title {
  color:grey;
}
.vitae {
  margin-top:0.5em;
}
.email {
  font-family:courier;
  margin-top:0.5em;
  margin-bottom:0.5em;
}
.button{
  border:none;
  outline:0;
  display:inline-block;
  padding:8px;
  color:white;
  background-color:#000;
  text-align:center;
  cursor:pointer;
  width:100%;
}
.button:hover{
  background-color:#555;
}
</style>
~~~
""" |> println