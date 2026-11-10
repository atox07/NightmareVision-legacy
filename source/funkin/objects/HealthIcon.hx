package funkin.objects;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	
	private var isPlayer:Bool = false;
	private var char:String = '';
	
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
	
	var iconOffsets:Array<Float> = [0, 0];
	
	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var name:String = 'icons/' + char;
			var graphic = Paths.image(name, null, false);
			if (graphic == null) graphic = Paths.image('icons/icon-' + char, null, false);
			if (graphic == null) graphic = Paths.image('icons/icon-face', null, false);
			if (graphic == null) throw 'Impossibile caricare l’icona "$char" o quella predefinita.';
			
			loadGraphic(graphic, true, Math.floor(graphic.width / 2), Math.floor(graphic.height)); // Then load it fr
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
			updateHitbox();
			
			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);
			this.char = char;
			
			antialiasing = char.endsWith('-pixel') ? false : ClientPrefs.globalAntialiasing;
		}
	}
	
	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
	
	public function getCharacter():String
	{
		return char;
	}
}
