// generated by Fast Light User Interface Designer (fluid) version 1.0304

#ifndef StracciatellaLauncher_h
#define StracciatellaLauncher_h
#include <FL/Fl.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Input_Choice.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Round_Button.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Box.H>

class StracciatellaLauncher {
public:
  StracciatellaLauncher();
  Fl_Double_Window *stracciatellaLauncher;
  Fl_Input *dataDirectoryInput;
  Fl_Input_Choice *gameVersionInput;
  Fl_Button *browseJa2DirectoryButton;
  Fl_Check_Button *fullscreenCheckbox;
  Fl_Round_Button *predefinedResolutionButton;
  Fl_Round_Button *customResolutionButton;
  Fl_Input_Choice *predefinedResolutionInput;
  Fl_Value_Input *customResolutionXInput;
  Fl_Value_Input *customResolutionYInput;
  Fl_Input_Choice *scalingModeInput;
  Fl_Check_Button *playSoundsCheckbox;
  Fl_Button *playButton;
  Fl_Button *editorButton;
};
#endif
