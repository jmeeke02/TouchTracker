//
//  BNRDrawView.m
//  
//
//  Created by Jordan Meeker on 5/5/15.
//
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) NSMutableArray *finishedLines;
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;

@property (nonatomic, weak) BNRLine *selectedLine;

@end

@implementation BNRDrawView

#pragma mark - Initializer

//Designated intiliazer for BNRDrawView

- (instancetype) initWithFrame: (CGRect) r {
   
   self= [super initWithFrame:r];
   
   if (self) {
      
      self.linesInProgress = [[NSMutableDictionary alloc] init];
      self.finishedLines = [[NSMutableArray alloc] init];
      self.backgroundColor = [UIColor grayColor];
      self.multipleTouchEnabled = YES;
      
      UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
      doubleTapRecognizer.delaysTouchesBegan = YES;
      doubleTapRecognizer.numberOfTapsRequired = 2;
      
      [self addGestureRecognizer:doubleTapRecognizer];
      
      UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
      tapRecognizer.delaysTouchesBegan =YES;
      
      //Require double tap to fail so you dont recignize both gestures
      [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
      [self addGestureRecognizer:tapRecognizer];
      
      
      //Long press recognizer
      UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
      [self addGestureRecognizer:pressRecognizer];
      
      self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
      
      self.moveRecognizer.delegate =self;
      self.moveRecognizer.cancelsTouchesInView = NO;
      [self addGestureRecognizer:self.moveRecognizer];
      
   }
   
   return self;
   
}

#pragma mark = Line Creation

//create the line with BezierPath

- (void) strokeLine:(BNRLine *) line {
   
   UIBezierPath *bp = [UIBezierPath bezierPath];
   bp.lineWidth = 10;
   bp.lineCapStyle = kCGLineCapRound;
   
   [bp moveToPoint:line.begin];
   [bp addLineToPoint:line.end];
   [bp stroke];
}

//draw the line

- (void) drawRect:(CGRect)rect {
   
   //Draw finished lines in Black
   
   [[UIColor blackColor] set];
   
   for (BNRLine *line in self.finishedLines) {
      [self strokeLine:line];
   }
   
   [[UIColor redColor] set];
   
   for (NSValue *key in self.linesInProgress){
      
      [self strokeLine:self.linesInProgress[key]];
   }
   
   if (self.selectedLine) {
      
      [[UIColor greenColor] set];
      [self strokeLine:self.selectedLine];
   }
      
}

- (BNRLine *) lineAtPoint:(CGPoint) p {
   
   //Find a line close to p
   for (BNRLine *l in self.finishedLines) {
      CGPoint start = l.begin;
      CGPoint end = l.end;
      
      //Check a few points on the line
      for (float t = 0.0; t <= 1.0; t += 0.05) {
         float x = start.x + t * (end.x - start.x);
         float y = start.y + t * (end.y - start.y);
         
         //If the tapped point is within 20 points, lets return this line
         if (hypot(x - p.x, y - p.y) <20.0) {
            return l;
         }
      }
      
   }
   //if nothing is close enough to the tapped point, then we do not select a line
   return nil;
}



#pragma mark - Gesture Actions

- (void) doubleTap: (UIGestureRecognizer *) gr {
   
   NSLog(@"Recognized Double Tap");
   
   [self.linesInProgress removeAllObjects];
   //[self.finishedLines removeAllObjects];
   
   self.finishedLines = [[NSMutableArray alloc] init];
   [self setNeedsDisplay];
}

- (void) tap: (UIGestureRecognizer *) gr {
   
   NSLog(@"Recognized tap");
   
   CGPoint point = [gr locationInView:self];
   self.selectedLine = [self lineAtPoint:point];
   
   if (self.selectedLine) {
      
      //Make ourselfes the target of the menu item aciton messages
      [self becomeFirstResponder];
      
      //Grab the menu controller
      UIMenuController *menu = [UIMenuController sharedMenuController];
      
      //Create a new "Delete" UIMenuItem
      UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
      
      menu.menuItems = @[deleteItem];
      
      //Tell the menu where it should come from and show it
      
      [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
      [menu setMenuVisible:YES animated:YES];
   } else {
      
      //Hide the menu if no line is selected
      [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
   }
   
   [self setNeedsDisplay];
   
}

- (void) deleteLine: (id) sender {
   
   //Remove the selecte line from list of finished lines
   [self.finishedLines removeObject:self.selectedLine];
   
   //Redraw everything
   [self setNeedsDisplay];
}

- (void) longPress: (UIGestureRecognizer *) gr {
   
   if (gr.state == UIGestureRecognizerStateBegan) {
      
      CGPoint point = [gr locationInView:self];
      self.selectedLine = [self lineAtPoint:point];
      
      if(self.selectedLine) {
         
         [self.linesInProgress removeAllObjects];
      }
      
   } else if (gr.state == UIGestureRecognizerStateEnded) {
         self.selectedLine = nil;
         
      }
      [self setNeedsDisplay];
      
      
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
   
   if (gestureRecognizer == self.moveRecognizer) {
      return YES;
   }
   
   return NO;
}

- (void) moveLine: (UIPanGestureRecognizer *) gr
{
   //If we have not selected a line we do not do anything here
   if (!self.selectedLine) {
      return;
   }
   
   //When the pan recognizer changes its position
   
   if(gr.state == UIGestureRecognizerStateChanged) {
      
      //How far has the pan moved
      CGPoint translation = [gr translationInView:self];
      
      //Add translation to the current beginning and end points of the selected line
      CGPoint begin = self.selectedLine.begin;
      CGPoint end = self.selectedLine.end;
      begin.x += translation.x;
      begin.y += translation.y;
      end.x += translation.x;
      end.y += translation.y;
      
      //Set the new beginning and ending points of the line
      self.selectedLine.begin = begin;
      self.selectedLine.end =end;
      
      //Redraw
      [self setNeedsDisplay];
      
      // need to resent the translation point to zero every time or else you are adding from the original point every time
      [gr setTranslation:CGPointZero inView:self];
   }
}


#pragma mark - Touch Events


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   
   
   NSLog(@"%@", NSStringFromSelector(_cmd));
   
   for (UITouch *t in touches) {
      
      CGPoint location = [t locationInView:self];
      
      BNRLine *line = [[BNRLine alloc] init];
      line.begin = location;
      line.end = location;
      
      //Get key for dictionary
      NSValue *key = [NSValue valueWithNonretainedObject:t];
      [self.linesInProgress setObject:line forKey:key];
      self.linesInProgress[key] = line;
   }
   
   [self setNeedsDisplay];
   
}


- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
   
   //Log the current method
   NSLog(@"%@", NSStringFromSelector(_cmd));
   
   for (UITouch *t in touches) {
      NSValue *key = [NSValue valueWithNonretainedObject:t];
      BNRLine *line = self.linesInProgress[key];
      
      line.end = [t locationInView:self];
   }
   
   [self setNeedsDisplay];
}



- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
   
   //Log the current method
   NSLog(@"%@", NSStringFromSelector(_cmd));
   
   for(UITouch *t in touches){
      
      NSValue *key = [NSValue valueWithNonretainedObject:t];
      BNRLine *line = self.linesInProgress[key];
      
      [self.finishedLines addObject:line];
      [self.linesInProgress removeObjectForKey:key];
      
      line.containingArray = self.finishedLines;
      
   }
   
   [self setNeedsDisplay];
   
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
   
   //Log which method
   NSLog(@"%@", NSStringFromSelector(_cmd));
   
   for(UITouch *t in touches){
      
      //remove any lines in progress
      NSValue *key = [NSValue valueWithNonretainedObject:t];
      [self.linesInProgress removeObjectForKey:key];
   }
   
   [self setNeedsDisplay];
}


#pragma mark Other

- (BOOL) canBecomeFirstResponder {
   
   return YES;
}


- (int) numberOfLines
{
   float count = 0;
   
   //Check that they are non-nil before we add their counts..
   if (self.linesInProgress && self.finishedLines) {
      count = [self.linesInProgress count] + [self.finishedLines count];
   }
   return count;
   
}



@end
