package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;

import funkin.backend.DebugDisplay;

class Main extends Sprite
{
	public static final PSYCH_VERSION:String = '0.5.2h';
	public static final NMV_VERSION:String = '0.2';
	public static final FUNKIN_VERSION:String = '0.2.7';
	
	public static final startMeta =
		{
			width: 1280,
			height: 720,
			fps: 60,
			skipSplash: #if debug true #else false #end,
			startFullScreen: false,
			initialState: funkin.states.TitleState
		};
		
	// You can pretty much ignore everything from here on - your code should go in your states.
	public static var fpsVar:DebugDisplay;

	public static function writeDiagnostic(message:String):Void
	{
		#if sys
		try
		{
			final output = sys.io.File.append("nightmarevision-diagnostic.log", false);
			output.writeString(Date.now().toString() + " " + message + "\n");
			output.close();
		}
		catch (error:Dynamic)
		{
			trace("Could not write diagnostic log: " + error);
		}
		#end
	}
	
	static function __init__()
	{
		funkin.utils.MacroUtil.haxeVersionEnforcement();
	}
	
	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}
	
	public function new()
	{
		super();
		writeDiagnostic("Starting NightmareVision");

		initHaxeUI();
		
		#if (windows && cpp)
		funkin.api.NativeWindows.setDarkMode();
		#end
		
		// load save data before creating FlxGame
		ClientPrefs.loadDefaultKeys();
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		
		var game = new
			#if CRASH_HANDLER
			FNFGame
			#else
			FlxGame
			#end(startMeta.width, startMeta.height, Init, startMeta.fps, startMeta.fps, true, startMeta.startFullScreen);
			
		// FlxG.game._customSoundTray wants just the class, it calls new from
		// create() in there, which gets called when it's added to stage
		// which is why it needs to be added before addChild(game) here
		
		// Also btw game has to be a variable for this to work ig - Orbyy
		
		@:privateAccess
		game._customSoundTray = funkin.objects.FunkinSoundTray;
		
		addChild(game);
		
		#if !mobile
		fpsVar = new DebugDisplay(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end
		
		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		FlxG.signals.gameResized.add(onResize);
		
		#if DISABLE_TRACES
		haxe.Log.trace = (v:Dynamic, ?infos:haxe.PosInfos) -> {}
		#end
	}
	
	@:access(flixel.FlxCamera)
	static function onResize(w:Int, h:Int)
	{
		final scale:Float = Math.max(1, Math.min(w / FlxG.width, h / FlxG.height));
		if (fpsVar != null)
		{
			// remove for now idfk some people have the textfield scaling fucky ???
			// fpsVar.scaleX = fpsVar.scaleY = scale;
		}
		
		if (FlxG.cameras != null)
		{
			for (i in FlxG.cameras.list)
			{
				if (i != null && i.filters != null) resetSpriteCache(i.flashSprite);
			}
		}
		
		if (FlxG.game != null)
		{
			resetSpriteCache(FlxG.game);
		}
	}
	
	public static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
	
	function initHaxeUI():Void
	{
		#if haxeui_core
		haxe.ui.Toolkit.init();
		haxe.ui.Toolkit.theme = 'dark';
		haxe.ui.Toolkit.autoScale = false;
		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
		#end
	}
}

#if CRASH_HANDLER
class FNFGame extends FlxGame
{
	var crashScreen:openfl.display.Sprite;
	var hasCrashed:Bool = false;

	function handleUncaughtError(event:openfl.events.UncaughtErrorEvent):Void
	{
		event.preventDefault();
		onCrash(event.error);
	}

	function blockGameplayKeys(event:openfl.events.KeyboardEvent):Void
	{
		if (hasCrashed) event.stopImmediatePropagation();
	}

	private static function crashGame()
	{
		null
		.draw();
	}
	
	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 */
	override function create(_):Void
	{
		loaderInfo.uncaughtErrorEvents.addEventListener(openfl.events.UncaughtErrorEvent.UNCAUGHT_ERROR, handleUncaughtError);
		Lib.current.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, blockGameplayKeys, true, 1000);
		Lib.current.stage.addEventListener(openfl.events.KeyboardEvent.KEY_UP, blockGameplayKeys, true, 1000);
		try
		{
			_skipSplash = true;
			super.create(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	override function onFocus(_):Void
	{
		if (hasCrashed) return;
		try
		{
			super.onFocus(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	override function onFocusLost(_):Void
	{
		if (hasCrashed) return;
		try
		{
			super.onFocusLost(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	/**
	 * Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	 */
	override function onEnterFrame(_):Void
	{
		if (hasCrashed) return;
		try
		{
			super.onEnterFrame(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	/**
	 * This function is called by `step()` and updates the actual game state.
	 * May be called multiple times per "frame" or draw call.
	 */
	override function update():Void
	{
		if (hasCrashed) return;
		#if CRASH_TEST
		if (FlxG.keys.justPressed.F9) crashGame();
		#end
		try
		{
			super.update();
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	/**
	 * Goes through the game state and draws all the game objects and special effects.
	 */
	override function draw():Void
	{
		if (hasCrashed) return;
		try
		{
			super.draw();
		}
		catch (e)
		{
			onCrash(e);
		}
	}
	
	private final function onCrash(e:Dynamic):Void
	{
		if (hasCrashed) return;
		hasCrashed = true;
		final stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack(true));
		final message = Std.string(e);
		final crashReport = 'Error caught: ' + message + '\nCallstack:\n' + stack;
		Main.writeDiagnostic(crashReport);

		// Use OpenFL directly so displaying the error does not load mod assets
		// or destroy the partially initialized gameplay state.
		final screenStage = Lib.current.stage;
		crashScreen = new openfl.display.Sprite();
		crashScreen.graphics.beginFill(0x151821);
		crashScreen.graphics.drawRect(0, 0, screenStage.stageWidth, screenStage.stageHeight);
		crashScreen.graphics.endFill();
		screenStage.addChild(crashScreen);

		final title = new openfl.text.TextField();
		title.defaultTextFormat = new openfl.text.TextFormat("_sans", 28, 0xFF8585, true);
		title.x = 24;
		title.y = 20;
		title.width = screenStage.stageWidth - 48;
		title.height = 45;
		title.text = "NightmareVision ha interrotto la partita";
		crashScreen.addChild(title);

		final details = new openfl.text.TextField();
		details.defaultTextFormat = new openfl.text.TextFormat("_sans", 16, 0xFFFFFF);
		details.x = 24;
		details.y = 80;
		details.width = screenStage.stageWidth - 48;
		details.height = Math.max(80, screenStage.stageHeight - 170);
		details.multiline = true;
		details.wordWrap = true;
		details.selectable = true;
		details.text = "Il motore ha incontrato un errore durante l'esecuzione.\n"
			+ "Il rapporto viene scritto in nightmarevision-diagnostic.log nella cartella di avvio.\n"
			+ "Puoi selezionare il testo e scorrerlo con la rotella.\n\n" + crashReport;
		details.addEventListener(openfl.events.MouseEvent.MOUSE_WHEEL, event -> {
			details.scrollV -= event.delta;
		});
		crashScreen.addChild(details);

		final restart = new openfl.text.TextField();
		restart.defaultTextFormat = new openfl.text.TextFormat("_sans", 20, 0xFFFFFF, true);
		restart.background = true;
		restart.backgroundColor = 0x354A70;
		restart.x = 24;
		restart.y = Math.max(170, screenStage.stageHeight - 65);
		restart.width = 300;
		restart.height = 38;
		restart.selectable = false;
		restart.text = "Riavvia il motore";
		restart.addEventListener(openfl.events.MouseEvent.CLICK, _ -> {
			try
			{
				FlxG.resetGame();
				screenStage.removeChild(crashScreen);
				crashScreen = null;
				hasCrashed = false;
			}
			catch (error:Dynamic)
			{
				Main.writeDiagnostic("Recovery error: " + error);
				details.appendText("\n\nRiavvio fallito: " + Std.string(error));
			}
		});
		crashScreen.addChild(restart);
		try
		{
			FlxG.sound.music?.stop();
		}
		catch (error:Dynamic)
		{
			Main.writeDiagnostic("Could not stop music after crash: " + error);
		}
	}
}
#end
