//
//  zhPickerView.m
//  zhPopupController
//
//  Created by zhanghao on 2017/9/14.
//  Copyright © 2017年 snail-z. All rights reserved.
//

@interface zhCurrentDateModel : NSObject

@property (nonatomic, strong) NSString *currentYear;
@property (nonatomic, strong) NSString *currentMonth;
@property (nonatomic, strong) NSString *currentDay;
@property (nonatomic, strong) NSString *currentHours;
@property (nonatomic, strong) NSString *currentMinutes;
@property (nonatomic, strong) NSString *currentWeek;
@property (nonatomic, assign) NSInteger currentDayIdx;

@end

@implementation zhCurrentDateModel

@end

#import "zhPickerView.h"

typedef NS_ENUM(NSInteger, zhDateType) { // 应该与allDataArray数组顺序一致
    zhDateTypeYear = 0,
    zhDateTypeMonth,
    zhDateTypeDay,
    zhDateTypeHours,
    zhDateTypeMinutes,
};

@interface zhPickerView () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) NSArray<NSString *> *yearArray;       // 年
@property (nonatomic, strong) NSArray<NSString *> *monthArray;      // 月
@property (nonatomic, strong) NSArray<NSString *> *weekArray;       // 周
@property (nonatomic, strong) NSArray<NSString *> *dayArray;        // 日
@property (nonatomic, strong) NSArray<NSString *> *hoursArray;      // 时
@property (nonatomic, strong) NSArray<NSString *> *minutesArray;    // 分
@property (nonatomic, strong) NSArray<NSString *> *amPmArray;       // 上午下午
@property (nonatomic, strong) NSMutableArray<NSArray<NSString *> *> *allDataArray;  // 所有数据

@property (nonatomic, strong) zhCurrentDateModel *currentDateModel; // 记录当前选中的数据

@end

@implementation zhPickerView

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        
        /** UIPickerView
         height设置区间在0～179 时，UIPickerView的height为162
         height设置区间在180～215时，UIPickerView的height为180
         height设置区间在216～∞时，UIPickerView的height为216
         */
        _pickerView= [[UIPickerView alloc] init];
        _pickerView.frame = CGRectMake(0, 0, frame.size.width, 216);
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.showsSelectionIndicator = YES;
        [self addSubview:_pickerView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = [UIColor darkGrayColor];
        [self addSubview:_titleLabel];
        
        _saveButton = [[UIButton alloc] init];
        [_saveButton setImage:[UIImage imageNamed:@"icon_select1"] forState:UIControlStateNormal];
        [_saveButton addTarget:self action:@selector(saveClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_saveButton];
        
        _cancelButton = [[UIButton alloc] init];
        [_cancelButton setImage:[UIImage imageNamed:@"icon_revocation1"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cancelButton];
        
        [self initialSelectedItem];
    }
    return self;
}

#pragma mark - Initial selected

- (void)initialSelectedItem {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    zhCurrentDateModel *model = self.currentDateModel;
    model.currentYear = [NSString stringWithFormat:@"%@年", @(components.year)];
    model.currentMonth = [NSString stringWithFormat:@"%@月", @(components.month)];
    model.currentDay = [NSString stringWithFormat:@"%@日", @(components.day)];
    model.currentHours = [NSString stringWithFormat:@"%@时", @(components.hour)];
    model.currentMinutes = [NSString stringWithFormat:@"%@分", @(components.minute+1)];
    model.currentDayIdx = components.day;

    [_pickerView selectRow:[self.yearArray zh_indexOfObject:model.currentYear] inComponent:0 animated:YES];
    [_pickerView selectRow:[self.monthArray zh_indexOfObject:model.currentMonth] inComponent:1 animated:YES];
    [_pickerView selectRow:[self.dayArray zh_indexOfObject:model.currentDay] inComponent:2 animated:YES];
    [_pickerView selectRow:[self.hoursArray zh_indexOfObject:model.currentHours] inComponent:3 animated:YES];
    [_pickerView selectRow:[self.minutesArray zh_indexOfObject:model.currentMinutes] inComponent:4 animated:YES];
    
    [self showTitleWithModel:self.currentDateModel];
}

#pragma mark - Button events

- (void)saveClicked {
    if (self.saveClickedBlock) {
        self.saveClickedBlock(self);
    }
}

- (void)cancelClicked {
    if (self.cancelClickedBlock) {
        self.cancelClickedBlock(self);
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat buttonWidth = 40, paddingLeft = 10, spacing = 10, paddingTop = 5;
    
    _cancelButton.size = CGSizeMake(buttonWidth, buttonWidth);
    _cancelButton.origin = CGPointMake(paddingLeft, paddingTop);
    
    _saveButton.size = CGSizeMake(buttonWidth, buttonWidth);
    _saveButton.right = self.width - paddingLeft;
    _saveButton.y = paddingTop;

    _titleLabel.width = self.width - (buttonWidth + paddingLeft + spacing) * 2;
    _titleLabel.height = buttonWidth;
    _titleLabel.centerX = self.width / 2;
    _titleLabel.y = paddingTop;
    
    CGFloat vSpacing = 10;
    CGFloat height = self.height - _titleLabel.bottom - vSpacing - UIScreen.safeInsets.bottom;
    _pickerView.size = CGSizeMake(self.width, height);
    _pickerView.y = _titleLabel.bottom + vSpacing;
}

#pragma mark - UIPickerViewDataSource

// 显示多少列
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return self.allDataArray.count;
}

// 各个component有多少行
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.allDataArray[component] count];
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 30)];
        pickerLabel.backgroundColor = [UIColor clearColor];
        pickerLabel.textAlignment = NSTextAlignmentCenter;
        pickerLabel.font = [UIFont systemFontOfSize:15];
        pickerLabel.textColor = [UIColor darkGrayColor];
        UIView *line1 = [_pickerView.subviews objectAtIndex:1]; // 两条线
        UIView *line2 = [_pickerView.subviews objectAtIndex:2];
        line1.height = line2.height = 0.5 / [UIScreen mainScreen].scale;
    }
    pickerLabel.attributedText = [self pickerView:pickerView attributedTitleForRow:row forComponent:component];
    return pickerLabel;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component  {
    NSString *string = self.allDataArray[component][row];
    NSAttributedString *attriText = [[NSAttributedString alloc] initWithString:string];
    return attriText;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *stringValue = self.allDataArray[component][row];
    switch (component) {
        case zhDateTypeYear: {
            self.currentDateModel.currentYear = stringValue;
            [self reloadDayComponent];
        } break;
            
        case zhDateTypeMonth: {
            self.currentDateModel.currentMonth = stringValue;
            [self reloadDayComponent];
        } break;
            
        case zhDateTypeDay: {
            self.currentDateModel.currentDay = stringValue;
            self.currentDateModel.currentDayIdx = row;
        } break;
            
        case zhDateTypeHours: {
            self.currentDateModel.currentHours = stringValue;
        } break;
            
        case zhDateTypeMinutes: {
            self.currentDateModel.currentMinutes = stringValue;
        } break;
            
        default: break;
    }
    [self showTitleWithModel:self.currentDateModel];
}

#pragma mark - Title text

- (void)showTitleWithModel:(zhCurrentDateModel *)model {
    NSString *string = [NSString stringWithFormat:@"%@-%@-%@",
                        [model.currentYear deleteLastCharacter],
                        [model.currentMonth deleteLastCharacter],
                        [model.currentDay deleteLastCharacter]];
    NSDate *date = [NSDate dateWithString:string format:@"yyyy-MM-dd"];
    NSString *weekString = [date dayFromWeekday2];
    
    /// 时间戳转换
    NSString *timeString = [NSString stringWithFormat:@"%@ %@:%@",
                            string,
                            [model.currentHours deleteLastCharacter],
                            [model.currentMinutes deleteLastCharacter]];
    _selectedTimeString = timeString;
    NSInteger timestamp = [NSDate timestampFromTimeString:timeString formatter:@"yyyy-MM-dd HH:mm"];
    _selectedTimestamp = timestamp;
    
    NSString *showText = [NSString stringWithFormat:@"%@%@%@ %@%@",
                          model.currentYear,
                          model.currentMonth,
                          model.currentDay,
                          model.currentHours,
                          model.currentMinutes];
    _titleLabel.text = showText;
}

#pragma mark - Data

// 年份
- (NSArray<NSString *> *)yearArray {
    if (!_yearArray) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
        NSInteger startYear = components.year, endYear = startYear+10;
        NSMutableArray *array = @[].mutableCopy;
        for (NSInteger i = startYear; i <= endYear; i++) {
            [array addObject:[NSString stringWithFormat:@"%@年", @(i)]];
        }
        _yearArray = array.copy;
    }
    return _yearArray;
}

// 月份
- (NSArray<NSString *> *)monthArray {
    if (!_monthArray) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:[NSDate date]];
        NSMutableArray *array = @[].mutableCopy;
        for (NSInteger i = 1; i <= 12; i++) {
            [array addObject:[NSString stringWithFormat:@"%@月", @(i)]];
        }
        _monthArray = array.copy;
    }
    return _monthArray;
}

// 当月的天数
- (NSArray<NSString *> *)dayArray {
    if (!_dayArray) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:[NSDate date]];
        NSMutableArray *array = @[].mutableCopy;
        for (NSInteger i = 1; i <= 31; i ++) { // 最多31天，具体天数需要根据年月计算
            [array addObject:[NSString stringWithFormat:@"%@日", @(i)]];
        }
        _dayArray = array.copy;
    }
    return _dayArray;
}

// 小时
- (NSArray<NSString *> *)hoursArray {
    if (!_hoursArray) {
        NSMutableArray *array = @[].mutableCopy;
        for (NSInteger i = 0; i < 24; i++) {
            [array addObject:[NSString stringWithFormat:@"%@时", @(i)]];
        }
        _hoursArray = array;
    }
    return _hoursArray;
}

// 分钟
- (NSArray<NSString *> *)minutesArray {
    if (!_minutesArray) {
        NSMutableArray *array = @[].mutableCopy;
        for (NSInteger i = 0; i < 60; i++) {
            [array addObject:[NSString stringWithFormat:@"%@分", @(i)]];
        }
        _minutesArray = array;
    }
    return _minutesArray;
}

// 所有数据
- (NSMutableArray<NSArray<NSString *> *> *)allDataArray {
    if (!_allDataArray) {
        _allDataArray = @[].mutableCopy;
        [_allDataArray addObject:self.yearArray];
        [_allDataArray addObject:self.monthArray];
        [_allDataArray addObject:self.dayArray];
        [_allDataArray addObject:self.hoursArray];
        [_allDataArray addObject:self.minutesArray];
    }
    return _allDataArray;
}

// 当前时间数据模型
- (zhCurrentDateModel *)currentDateModel {
    if (!_currentDateModel) {
        _currentDateModel = [zhCurrentDateModel new];
    }
    return _currentDateModel;
}


#pragma mark - Tool

- (void)reloadDayComponent {
    NSInteger monthInt = [self.currentDateModel.currentMonth deleteLastCharacter].integerValue;
    NSInteger yearInt = [self.currentDateModel.currentYear deleteLastCharacter].integerValue;
    [self reloadNumberDaysBy:monthInt inYear:yearInt];
}

- (void)reloadNumberDaysBy:(NSInteger)aMonth inYear:(NSInteger)aYear {
    if (!aMonth || !aYear) return;
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM"];
    NSString *dateString = [NSString stringWithFormat:@"%lu-%lu", aYear, aMonth];
    NSDate *date = [formatter dateFromString:dateString];
    NSRange daysInMonth = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    
    NSInteger i = (components.year==aYear)?components.month:1;
    /*
    if (aMonth<i) {
        self.currentDateModel.currentMonth = [NSString stringWithFormat:@"%@月", @(i)];
    }
    NSMutableArray *months = [NSMutableArray array];
    for (; i <= 12; i++) {
        [months addObject:[NSString stringWithFormat:@"%@月", @(i)]];
    }
    NSInteger idx = [self.allDataArray indexOfObject:self.monthArray];
    self.monthArray = months;
    [self.allDataArray replaceObjectAtIndex:idx withObject:self.monthArray];
    [self.pickerView reloadComponent:idx];
    [_pickerView selectRow:[self.monthArray zh_indexOfObject:_currentDateModel.currentMonth] inComponent:1 animated:YES];
    aMonth = [self.currentDateModel.currentMonth deleteLastCharacter].integerValue;
     //*/
    
    i = (components.year==aYear&&components.month==aMonth)?components.day:1;
    NSInteger dayInt = [self.currentDateModel.currentDay deleteLastCharacter].integerValue;
    if (dayInt<i) {
        self.currentDateModel.currentDay = [NSString stringWithFormat:@"%@日", @(i)];
    } else if (dayInt>daysInMonth.length) {
        self.currentDateModel.currentDay = [NSString stringWithFormat:@"%@日", @(daysInMonth.length)];
    }
    NSMutableArray *days = [NSMutableArray array];
    for (; i <= daysInMonth.length; i++) {
        [days addObject:[NSString stringWithFormat:@"%@日", @(i)]];
    }
    NSInteger idx = [self.allDataArray indexOfObject:self.dayArray];
    self.dayArray = days;
    [self.allDataArray replaceObjectAtIndex:idx withObject:self.dayArray];
    [self.pickerView reloadComponent:idx];
    [_pickerView selectRow:[self.dayArray zh_indexOfObject:_currentDateModel.currentDay] inComponent:2 animated:YES];
}

- (void)reloadHourComponent {
    NSInteger dayInt = [self.currentDateModel.currentDay deleteLastCharacter].integerValue;
    NSInteger hourInt = [self.currentDateModel.currentHours deleteLastCharacter].integerValue;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger i = (components.day==dayInt)?components.hour:0;
    NSMutableArray *array = [NSMutableArray array];
    for (; i < 24; i++) {
        [array addObject:[NSString stringWithFormat:@"%@分", @(i)]];
    }
    NSInteger idx = [self.allDataArray indexOfObject:self.hoursArray];
    self.hoursArray = array.copy;
    [self.allDataArray replaceObjectAtIndex:idx withObject:self.hoursArray];
    if (hourInt < components.hour) {
        self.currentDateModel.currentHours = array.firstObject;
    }
}

- (void)reloadMinuteComponent {
    NSInteger hourInt = [self.currentDateModel.currentHours deleteLastCharacter].integerValue;
    NSInteger minuteInt = [self.currentDateModel.currentMinutes deleteLastCharacter].integerValue;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    NSInteger i = (components.hour==hourInt)?components.minute:0;
    NSMutableArray *array = [NSMutableArray array];
    for (; i < 60; i++) {
        [array addObject:[NSString stringWithFormat:@"%@分", @(i)]];
    }
    NSInteger idx = [self.allDataArray indexOfObject:self.minutesArray];
    self.minutesArray = array.copy;
    [self.allDataArray replaceObjectAtIndex:idx withObject:self.minutesArray];
    if (minuteInt < components.minute) {
        self.currentDateModel.currentHours = [NSString stringWithFormat:@"%@分", @(components.minute)];
    }
}

// 返回正确的分钟下标 (分钟取整，小于10分取整分)
- (NSInteger)correctIdx:(NSInteger)currentMinutes {
    if ((currentMinutes % 10) > 0) {
        NSInteger idx = (currentMinutes + 10) / 10;
        if (idx > 5) idx = 0;
        return idx;
    } else {
        return currentMinutes / 10;
    }
}

@end
