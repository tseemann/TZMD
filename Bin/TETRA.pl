#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);

die "perl $0 [list][*_Zvalue.xls][output]" unless (@ARGV==3);
my $current_time;
$current_time = strftime "%Y-%m-%d %H:%M:%S", localtime;
print STDERR "$current_time: Start ...\n";

######################################################## Intializing for Zvalue ##############################################
my $km=4;
my @mono=("A","T","G","C");
our @oligo_kmer=();
our (@oligo_k_1mer,@oligo_k_2mer)=((),());
my @nuc=@mono;
my $index=1;
while(){
	my @tmpnuc=();
	$index++;
	foreach(@mono){
		my $word=$_;
		foreach (@nuc){
			my $nuc=$word."$_";
			push @tmpnuc,$nuc;
		}
	}
	@nuc=@tmpnuc;
	if($index == $km-2){
		@oligo_k_2mer=@nuc;
	}
	elsif($index == $km -1){
		@oligo_k_1mer=@nuc;
	}
	elsif($index == $km){
		@oligo_kmer=@nuc;
		last;
	}
}
$current_time = strftime "%Y-%m-%d %H:%M:%S", localtime;
print STDERR "$current_time: Finish Intializing for zvalues\n";

##################################################################### Sequences  ##################################################
open(LIST,$ARGV[0])||die;
my @ID=();
my (%refxx,%SSxx,%sp);
while(<LIST>){
	chomp;
	my @a=split /\t/;
	my $id=shift @a;
	my $spid=shift @a;
	$sp{$id}=$spid;
	push @ID,$id;
	shift @a;
	my $zvalueref=\@a;
	my $mean=&mean($zvalueref);
	my @d=();
	foreach(@a){
		my $tmp=$_-$mean;
		push @d,$tmp;
	}
	my $refxx=\@d;
	my $SSxx=&SS($refxx,$refxx,__LINE__);
	$refxx{$id}=$refxx;
	$SSxx{$id}=$SSxx;
}
close LIST;

#################################################### correlation for same genus  #################################################
open(IF,$ARGV[1])||die;
open(OUT,">$ARGV[2]")||die;
while(<IF>){
	chomp;
	my @a=split /\t/;
	my $id=shift @a;
	my $spid=shift @a;
	shift @a;
	my $zvalueref=\@a;
	my $mean=&mean($zvalueref);
	my @d=();
	foreach(@a){
		my $tmp=$_-$mean;
		push @d,$tmp;
	}
	my $refxx=\@d;
	my $SSxx=&SS($refxx,$refxx,__LINE__);
	foreach my $k (@ID){
		if($k eq $id){
			next;
		}
		else{
			my $refyy=$refxx{$k};
			my $SSyy=$SSxx{$k};
			my $SSxy=&SS($refxx,$refyy,__LINE__);
			my $cor=&correlation($SSxx,$SSyy,$SSxy);
			$cor=sprintf("%.2f",$cor);
			print OUT "$id\t$spid\t$k\t$sp{$k}\t$cor\n";
		}
	}
}
close OUT;
close IF;
$current_time = strftime "%Y-%m-%d %H:%M:%S", localtime;
print STDERR "$current_time: Finish calculating correlation for sp. of the same genus\n";

###################################################### Subroutine for computing mean##########################################################
sub mean{
	my ($ref)=@_;
	my @a=@{$ref};
	my $sum=0;
	foreach(@a){
		$sum+=$_;
	}
	my $mean=$sum/@a;
	return $mean;
}

###################################################### Subroutine for computing covariance or variance##########################################
sub SS{
	my ($ref1,$ref2,$line)=@_;
	if(!$ref1){
		print STDERR "$line\n";
	}
	my @a1=@{$ref1};
	if(!$ref2){
		print STDERR "$line\n";
	}
	my @a2=@{$ref2};
	my $sum=0;
	for (my $k=0;$k<=$#a1;$k++){
		$sum+=$a1[$k]*$a2[$k];
	}
	return $sum;
}

##################################################### Subroutine for computing Pearson correlation coefficient ##################################
sub correlation {
	my ($ssxx,$ssyy,$ssxy)=@_;
	my $correl=0;
	if($ssxy !=0 && $ssxx !=0 && $ssyy!=0){
		my $sign=$ssxy/abs($ssxy);
		$correl=$sign*sqrt($ssxy*$ssxy/($ssxx*$ssyy));
	}
	else{
		$correl="0";
	}
	return $correl;
}


