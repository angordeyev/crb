defmodule Ce do
  def to_boolean(1), do: true
  def to_boolean(0), do: false
  def to_boolean("1"), do: true
  def to_boolean("0"), do: false
  def map_to_string(map) do
    map 
      |> Enum.each(fn {k,v} -> "#{k}: #{v}" end)
      |> Enum.join("\n")
  end  

  def local_now_string do
    Timex.format!(Timex.now("Europe/Moscow"), "{ISO:Extended}") |> String.replace("T", " ") |> String.replace("+03:00", "")
  end  

  def format_num(value) do
    :erlang.float_to_binary(value, [ {:decimals, 8}, :compact  ])
  end

  def parse(text, template) do       
    text_length = String.length(text)   
    {left_template, right_template} = ptemplate(template)
    left_value_index = tmatch(text, left_template) + String.length(left_template)
    {right_template_index, _} = :binary.match(text, right_template, [{:scope, {left_value_index, text_length - left_value_index }}])        
    right_value_index = right_template_index - 1
    String.slice(text, left_value_index, right_value_index - left_value_index + 1)
  end  
  
  def tmatch(text, template) do 
    {result, _} = :binary.match(text, template)
    result
  end  

  def ptemplate(template) do
    left_placeholder_pattern = "{{"
    right_placeholder_pattern = "}}"
    left_template =  String.slice(template, 0, tmatch(template, left_placeholder_pattern))
    right_template_index= tmatch(template, right_placeholder_pattern) + String.length(right_placeholder_pattern)    
    right_template = String.slice(template, right_template_index, String.length(template) - right_template_index)    
    {left_template, right_template}
  end 

  def http_get(request) do
    { :ok, %HTTPoison.Response{body: body} } = HTTPoison.get request 
    Poison.decode! body 
  end  

  def now() do
    DateTime.utc_now |> DateTime.to_unix(:millisecond)
  end  

  def now_text() do
    DateTime.utc_now() |> DateTime.to_string()    
  end

end