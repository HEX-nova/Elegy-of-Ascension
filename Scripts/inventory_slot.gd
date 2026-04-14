extends PanelContainer

func setup(item_data: ItemData):
	# Match these names to exactly what you named your Label nodes!
	$HBox/icon.texture = item_data.icon
	
	# We use str() to convert the numbers (int/float) into text for the labels
	$HBox/Vbox/name.text = item_data.name
	$HBox/Vbox/value.text = "Value: " + str(item_data.value) + "g"
	$HBox/Vbox/weight.text = "Weight: " + str(item_data.weight) + "kg"
	$HBox/Vbox/quantity.text = "×" + str(item_data.quantity)
