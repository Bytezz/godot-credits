## Coded by Bytez
## https://github.com/bytezz/godot-credits
## ----
## Credits scroll scene rich of options
## (for Godot Game Engine).

extends Control

signal ended

## Container of all scrolling nodes
@onready var scrollingContainer = get_node("scrollingContainer")
## Container of titles and names
@onready var scrollingTextScene = preload("res://credits-scene/scrollingText.tscn")
## An image to use as Title for the credits
@onready var titleImg = get_node("scrollingContainer/titleImg")
## The credits file (formatted like a INI file (more info inside README.md))
@export_file var creditsFile: String

var viewSize # The size of the window
## Speed of scrolling
@export var speed = 40
var regularSpeed # To keep track of the original speed
var done = false # True if all the credits have been scrolled off the screen
#				 # (don't change this value, to end just use "end" function)
var is_first_frame = true

var file
var credits

## An image to use as Title for the credits
@export var titleImage: Texture2D

## The color of the background (covered if there is a video)
@export var backgroundColor: Color = Color.BLACK
## Video to play in background instead of having just a solid color
@export var backgroundVideo: VideoStream
## Do you want the video to be restarted once finished?
@export var loopVideo = true

## Color of the text on left side
@export var titlesColor: Color = Color.GRAY
## Color of the text on right side
@export var namesColor: Color = Color.WHITE
## Custom font
@export var customFont: Font
## Space between left and right sides
@export var margin: int = 6

## Playlist of music to play during credits scroll
@export var musicPlaylist: Array[AudioStream]
## Do you want the playlist to be restarted once finished?
@export var loopPlaylist = false
var playlistIndex = 0

## Do you want to enable go faster, go slower, pause and reverse controls with ui_actions?
@export var enableControls = true
@export var speedUpControl = "ui_up"
@export var slowDownControl = "ui_down"
## Do you want to be able to skip all the credits by pressing ui_accept?
@export var enableSkip = true
@export var skipControl = "ui_accept"

## The next scene to load once the scroll ended
@export var nextScene: PackedScene
## If true and there is no nextScene selected, once the scroll ended the program will quit
@export var quitOnEnd = false
## If true and there is no nextScene selected and quitOnEnd is false, once the scroll ended the node will be destroyed
@export var destroyOnEnd = false

func _ready():
	viewSize = get_viewport().size
	scrollingContainer.position.y = viewSize.y*2 # it's multiplied by two as a workaround. Look at _process function
	regularSpeed = speed
	
	# Set title image if there is one, otherwise delete the useless node
	if titleImage != null:
		titleImg.texture = titleImage
	else:
		titleImg.queue_free()
	
	# Set background video if there is one, otherwise delete the useless node
	if backgroundVideo != null:
		$backgroundVideo.stream = backgroundVideo
		$backgroundVideo.play()
	else:
		$backgroundVideo.queue_free()
	
	$background.color = backgroundColor
	
	# If the playlist has at list one track, play it
	if musicPlaylist.size() > 0 and musicPlaylist[playlistIndex] != null:
		playlist_track(playlistIndex)
	
	# Verify if a credits file has been provided
	if creditsFile == null or creditsFile == "":
		push_error("At least one credits file must be provided.")
		assert(false)
	
	# Verify if credits file exists
	if not FileAccess.file_exists(creditsFile):
		push_error("Credits file does not exist.")
		assert(false)
	# Well, open the credits file and read it
	file = FileAccess.open(creditsFile, FileAccess.READ)
	credits = file.get_as_text()
	file.close()
	
	# Parse the credits file
	var scrollingText = null
	var centeredText = null
	var titles
	var names
	var lines = credits.split("\n")
	var line
	for i in lines.size():
		lines[i] = lines[i].strip_edges()
		line = lines[i]
		if line.begins_with("{") and line.ends_with("}"):
			scrollingText = null
			centeredText = Label.new()
			
			# Center text
			centeredText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			centeredText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			# Color and font
			centeredText.add_theme_color_override("font_color",namesColor)
			if customFont != null:
				titles.add_theme_font_override("font", customFont)
			
			line = line.erase(0,1)
			line = line.erase(line.length()-1,1)
			centeredText.text += tr(line.strip_edges())
			
			scrollingContainer.add_child(centeredText)
			centeredText = null
		else:
			if scrollingText == null:
				scrollingText = scrollingTextScene.instantiate()
				titles = scrollingText.get_node("margin/Titles")
				names = scrollingText.get_node("margin2/Names")
				
				# Set colors
				titles.add_theme_color_override("font_color",titlesColor)
				names.add_theme_color_override("font_color",namesColor)
				
				# Set the custom font (if there is one)
				if customFont != null:
					titles.add_theme_font_override("font", customFont)
					names.add_theme_font_override("font", customFont)
				
				# Set the margin (the space between left and right panels)
				@warning_ignore("integer_division")
				scrollingText.get_node("margin").add_theme_constant_override("margin_right", margin/2)
				@warning_ignore("integer_division")
				scrollingText.get_node("margin2").add_theme_constant_override("margin_left", margin/2)
				
				scrollingContainer.add_child(scrollingText)
			
			if line == "":
				titles.text += "\n"
				names.text += "\n"
				if i>0 and (lines[i-1].begins_with("[") and lines[i-1].ends_with("]")):
					titles.text += "\n"
					names.text += "\n"
			elif line.begins_with("[") and line.ends_with("]"):
				if i>0 and (lines[i-1].begins_with("[") and lines[i-1].ends_with("]")):
					titles.text+="\n"
					names.text+="\n"
				line = line.erase(0,1)
				line = line.erase(line.length()-1,1)
				titles.text += tr(line.strip_edges())
			else:
				names.text += line+"\n"
				titles.text += "\n"


func _process(delta):
	# For some reason the position of the container is shifted once displayed.
	# This workaround fix it
	if is_first_frame:
		viewSize = get_viewport().size
		scrollingContainer.position.y = viewSize.y
		is_first_frame = false
	
	if not done:
		# If the scroll is not yet ended, keep to scroll it
		if scrollingContainer.position.y+scrollingContainer.size.y > 0:
			scrollingContainer.position.y -= speed*delta
		else:
			end()

# On video end, replay it if it's enable the loop
func _on_backgroundVideo_finished():
	if loopVideo:
		$backgroundVideo.play()

# Function to change playing track of playlist
func playlist_track(index):
	if 0 <= index and index < musicPlaylist.size():
		musicPlaylist[index].loop = false
		$musicPlayer.stream = musicPlaylist[index]
		$musicPlayer.play()
		playlistIndex = index

# On track end, check if there is another track in the playlist after it
# if not, and the playlist loop is enabled, restart the playlist
func _on_musicPlayer_finished():
	if playlistIndex+1 < musicPlaylist.size():
		playlist_track(playlistIndex+1)
	elif loopPlaylist:
			playlistIndex = 0
			playlist_track(playlistIndex)

func _input(event):
	if not done:
		# If there is still text scrolling and controls are enabled,
		# let the gamer speed it up, slow it down, stop it or reverse it
		if enableControls:
			if event.is_action_pressed(slowDownControl):
				speed -= 10 * event.get_action_strength(slowDownControl)
			if event.is_action_pressed(speedUpControl):
				speed += 10 * event.get_action_strength(speedUpControl)
		# If skip is enable, let the gamer skip the credits
		if enableSkip:
			if event.is_action_pressed(skipControl):
				end()
				#speed *= 100

# Use this function to stop all
func end():
	emit_signal("ended") # Emit a signal to make easy for programmers to connect other things to this
	done = true # And a var, to make things even more easy to connect
	
	# If there is a next scene to load, then load it,
	# otherwise if quitOnEnd is enabled, just quit
	if nextScene != null:
		# warning-ignore:return_value_discarded
		get_tree().change_scene_to_file(nextScene.get_path())
	elif quitOnEnd:
		get_tree().quit()
	elif destroyOnEnd:
		self.queue_free()
