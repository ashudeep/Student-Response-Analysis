#!/usr/bin/perl



BEGIN{
$SWPATH = defined $ENV{SWPATH} ? $ENV{SWPATH} : '/group/project/onrbee/BEETLE-ROOT/BEETLE-SUPPORT-SW';
}

use lib "$SWPATH/perllib/share/perl5";

use strict;

use Lingua::Stem;
use Text::Similarity::Overlaps;
use XML::SAX;



my $stemmer = Lingua::Stem->new;
my %options = ('normalize' => 1, 'stem' => 1, 'verbose' => 1, 'verbose_return' => 1);
my $similarity = Text::Similarity::Overlaps->new (\%options);


#my @stemmed = @{$stemmer->stem( split(/\s+/,"I liked play") )};
#print STDERR @stemmed;

my $printHeader = 0;
my $mode = "5way";

for (my $i=0; $i <= $#ARGV; $i++) {
    if ($ARGV[$i] eq "-h") {
	$printHeader = 1;
    } elsif (($ARGV[$i] eq "-m") && ($i < $#ARGV)) {
	$mode = $ARGV[$i+1];
	$i++
    }
}

#print STDERR "Mode is $mode\n";

my $filter = AnswerFeatureExtractor->new(Similarity => $similarity, Mode => $mode);
my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);

#my %parser_args = ();
my %parser_args = (Source => {ByteStream => \*STDIN});

if ($printHeader) {
    $filter->printHeader();
}

$parser->parse(%parser_args);


# end main


# Transformation -- print out the answers for now
package AnswerFeatureExtractor;
use strict;

use constant QUESTION_CONTENT => "questionText";
use constant EXPECTED_ANSWER => "referenceAnswer";
use constant STUDENT_ANSWER => "studentAnswer";

#use base qw(XML::Filter::Base);

sub new {
  my $class = shift;
  my %options = @_;
  $options{QuestionText} = '';
  $options{ExpectedAnswers}=[];
  $options{CollectingText}=0;
  $options{CurrentText}='';
  $options{CurrentAccuracy}='';
  $options{CurrentId}='';
  $options{ValueMap}={};
  if (exists $options{Mode}) {      
      if ($options{Mode} eq "2way") {
	  # print STDERR "Using 2-way value map";
	  $options{ValueMap} = { "correct" => "correct",
				 'partially_correct_incomplete' => "incorrect", 
				 'contradictory' => "incorrect",
				 'irrelevant' => "incorrect",
				 'non_domain' => "incorrect" };
      } elsif ($options{Mode} eq "3way") {			 
	  # print STDERR "Using 3-way value map";
	  $options{ValueMap} = { "correct" => "correct",
				 'partially_correct_incomplete' => "incorrect", 
				 'contradictory' => "contradictory",
				 'irrelevant' => "incorrect",
				 'non_domain' => "incorrect" }
      };
  }

  return bless \%options, $class;
}


sub printHeader {
    my ($self) = @_;
    # print the header
    print '@RELATION accuracy',"\n\n";
    
    print '@ATTRIBUTE id STRING',"\n";
    print '@ATTRIBUTE overlap NUMERIC',"\n";
    print '@ATTRIBUTE F NUMERIC',"\n";
    print '@ATTRIBUTE lesk NUMERIC',"\n";
    print '@ATTRIBUTE cosine NUMERIC',"\n";
    print '@ATTRIBUTE questionOverlap NUMERIC',"\n";
    print '@ATTRIBUTE questionF NUMERIC',"\n";
    print '@ATTRIBUTE questionLesk NUMERIC',"\n";
    print '@ATTRIBUTE questionCosine NUMERIC',"\n";

    
    if ($self->{Mode} eq "2way") {
	print '@ATTRIBUTE accuracy {correct,incorrect}',"\n";
    }
    elsif ($self->{Mode} eq "3way") {
	print '@ATTRIBUTE accuracy {correct,contradictory,incorrect}',"\n";
    } else {
	print '@ATTRIBUTE accuracy {correct,partially_correct_incomplete,contradictory,irrelevant,non_domain}',"\n";
    }
	
    print "\n",'@DATA',"\n";
}




sub start_element {
  my ($self, $element) = @_;
  my $name = $element->{Name};
  my %attrs = %{$element->{Attributes}};
  
  print STDERR "Starting element $name\n";

  if ($name eq STUDENT_ANSWER) {
      my $id = $attrs{'{}id'}->{Value};
      #print STDERR "Student answer with id $id and accuracy   $attrs{'{}accuracy'}->{Value}\n";
      $self->processAccuracy($attrs{'{}accuracy'}->{Value});
      $self->{CollectingText} = 1;
      $self->{CurrentText} = '';
      $self->{CurrentId} = $id;
  } elsif ($name eq EXPECTED_ANSWER) {
      print STDERR "Starting to process expected answer \n";
      $self->{CollectingText} = 1;
      $self->{CurrentText} = '';
      $self->{CurrentId} = '';
  } elsif ($name eq QUESTION_CONTENT) {
      $self->{CollectingText} = 1;
      $self->{CurrentText} = '';
      $self->{CurrentId} = '';
  }
}

sub processAccuracy {
    my ($self, $accuracy) = @_;
    # the default is to use accuracy value, but we will collapse it depending on the mode
    my $currentAccuracy = $accuracy;
    if (exists $self->{ValueMap}->{$accuracy}) {
	$currentAccuracy = $self->{ValueMap}->{$accuracy};
    }
    $self->{CurrentAccuracy} = $currentAccuracy;
}

sub end_element {
  my ($self, $element) = @_;
  my $name = $element->{Name};

  if ($name eq STUDENT_ANSWER) {
      $self->processStudentAnswer($self->{CurrentText});
      $self->{CollectingText} = 0;
      $self->{CurrentId} = '';
  } elsif ($name eq EXPECTED_ANSWER) {
      push @{$self->{ExpectedAnswers}},$self->{CurrentText};
      $self->{CollectingText} = 0;
  } elsif ($name eq QUESTION_CONTENT) {
      $self->{QuestionText} = $self->{CurrentText};
      $self->{CollectingText} = 0;
  }
}

sub characters {
    my ($self, $chars) = @_;
    if( $self->{CollectingText} ) {
	$self->{CurrentText} = $self->{CurrentText} . $chars->{Data};
    }
}

sub processStudentAnswer {
    my ($self, $answer) = @_;
    # compute maximum scores
    my $overlapMax = 0;
    my $cosineMax = 0;
    my $fMax = 0;
    my $leskMax = 0;
    my $expected_ans="";
#    print STDERR "My expected asnwers are : ", @{$self->{ExpectedAnswers}}, "\n";

    my $accuracy = $self->{CurrentAccuracy};
    my $id = $self->{CurrentId};

    if (($accuracy =~ /\S+/) && ($accuracy ne "unspecified") &&  ($accuracy ne "unexpected_give")) {
	my $answer_file="answers.csv";
	my $ref_answer_file="ref_answers.csv";
  
	open (MYFILE,">>$answer_file");
  open (MYFILE2,">>$ref_answer_file");
	for my $expected (@{$self->{ExpectedAnswers}}) {
	    my ($score, %allScores) = $self->{Similarity}->getSimilarityStrings($answer, $expected);
#	print STDERR "Similarity between $answer and $expected ", %score, "\n";
		#print STDERR "Expected: $expected and Answer:$answer \n";
	    #$expected_ans=$expected;
      my $question_text= $self->{QuestionText};
      print MYFILE2 "$id\t$question_text\t$expected\n";
	    if ($allScores{raw} > $overlapMax) {
		$overlapMax = $allScores{raw};
		#$expected_ans=$expected
	    }
	    
	    if ($allScores{F} > $fMax) {
		$fMax = $allScores{F};
	    }
	    
	    if ($allScores{cosine} > $cosineMax) {
		$cosineMax = $allScores{cosine};
	    }
	    
	    if ($allScores{lesk} > $leskMax) {
		$leskMax = $allScores{lesk};
	    }
	}

	my $id = $self->{CurrentId};
	my ($questionScore, %allQuestionScores) = $self->{Similarity}->getSimilarityStrings($answer, $self->{QuestionText});
	my $qOverlap = $allQuestionScores{raw};
	my $qf = $allQuestionScores{F};
	my $qcosine=$allQuestionScores{cosine};
	my $qlesk=$allQuestionScores{lesk};
	my $question_text= $self->{QuestionText};
       print MYFILE "$id\t$question_text\t$answer\t$expected_ans\n";
	print "$id,$overlapMax,$fMax,$leskMax,$cosineMax,$qOverlap,$qf,$qlesk,$qcosine,$accuracy\n"
    }
    close(MYFILE);    
}
    


